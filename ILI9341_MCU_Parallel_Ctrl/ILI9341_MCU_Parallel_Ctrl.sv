/**
 * ILI9341_Ctrl
 * Joshua Vasquez
 * December 24, 2014
 */
`include <filePaths.sv>


module ILI9341_MCU_Parallel_Ctrl( input logic clk, reset, 
    output logic [7:0] tftParallelPort,
    output logic tftChipSelect, tftWriteEnable, tftReset, tftDataCmd);

    logic slowClk;
    logic [15:0] pixelDataIn;   
    logic [16:0] pixelAddr; // large enough for 320*240 = 76800 pixel addresses

    clkDiv clkDivInst (.clk(clk), .reset(reset), .divInput(8'b0), 
                       .slowClk(slowClk));                                          
               


    ILI9341_8080_I_Driver driverInst( .clk(slowClk), .reset(reset),
                               .newFrameStrobe(1'b0), 
                               .dataReady(1'b1),
                                .pixelDataIn(pixelDataIn), 
                               .pixelAddr(pixelAddr),
                               .tftParallelPort(tftParallelPort),
                               .tftChipSelect(tftChipSelect), 
                               .tftWriteEnable(tftWriteEnable),
                               .tftReset(tftReset),
                               .tftDataCmd(tftDataCmd));

    pixelData pixelDataInst( .memAddress(pixelAddr), .memData(pixelDataIn)); 
endmodule


/**
 * \brief the main logic block containing the finite-state machine to drive
 *        the display. Display settings are stored in ram internal to this 
 *        module.
 */
module ILI9341_8080_I_Driver(   
/// standard clock and reset signals
        input logic clk, reset,
/// a positive edge indicates the start of a new frame 
        input logic newFrameStrobe, 
/// restricts when new data is sent out to the display. Hard-wire to 1 if 
/// not needed.
        input logic dataReady,     
/// a 16-bit pixel in RGB565 format
        input logic [15:0] pixelDataIn,
/// address of the desired pixel (if grabbing data from an external memory
/// location).
        output logic [16:0] pixelAddr,
        output logic [7:0] tftParallelPort,
        output logic tftChipSelect, 
        output logic tftWriteEnable, 
        output logic tftReset,
 /// indicates whether parallel bus byte is cmd or data based on memory values
        output logic tftDataCmd); 

//// BEGIN: CONSTANTS 
/// number of values in the memory containing all of the initialization values.
    parameter NUM_INIT_PARAMS = 95;

/// number of values in the memory containing the data sent at the start of a 
/// new frame.
    parameter NUM_FRAME_START_PARAMS = 12;

/// Total number of pixels.
    parameter NUM_PIXELS = 76800;
    parameter ROWS_ = 320;
    parameter COLS_ = 240;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter MS_120 = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter MS_5 = 250000; // 120 MS in clock ticks at 50 MHz
    parameter MS_FOR_RESET = 10000000;  // delay time in clock ticks for reset
//// END: CONSTANTS 


    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);


    logic [16:0] memAddr;
    logic [16:0] lastAddr;

/// Bit 8 (for next both addresses below) indicates whether a command or data 
/// is to be sent out on the parallel bus. 
    logic [8:0] initParamData;  
    logic [8:0] pixelLocData;

    logic [7:0] pixelData;

/// resetMemAddr is the signal to reset mem address location to 0 each time the
/// current block of data has finished writing for the given states.
    logic resetMemAddr; 

/// memory for accessing initialziation parameters for the ILI9341
    initParams initParamsInst(.memAddress(memAddr[6:0]),
                              .memData(initParamData));
/// memory containing parameters to send over at the start of each new frame
    pixelStartParams pixelStartParamsInst(.memAddress(memAddr[6:0]),
                              .memData(pixelLocData));

/// the value read from any of the given memory blocks that is to be written 
/// out over parallel port
    logic [15:0] memVal; 
                         
    /// TODO remove or repurpose
    logic [7:0] spiDataToSend;  /// value to be sent out over SPI protocol.

    logic MSB;

/// pixelAddr is basically memAddr once initialization is finished.
    assign pixelAddr = memAddr;

    typedef enum logic [3:0] {INIT, TRANSFER_SYNC, HOLD_RESET, SEND_INIT_PARAMS, 
                              WAIT_TO_SEND, SEND_PIXEL_LOC, SEND_DATA, DONE} 
                             stateType;
/*
    typedef enum logic [2:0] {INIT, HOLD_RESET, SEND_INIT_PARAMS, 
                              WAIT_TO_SEND, SEND_PIXEL_LOC, SEND_DATA, DONE} 
                             stateType;
*/
    stateType state;

/// Logic for resetMemAddr
    always_ff @ (posedge clk)
    begin
        if (reset)
        begin
            resetMemAddr <= 'b1;
        end
        else 
        begin
            resetMemAddr <= (memAddr == lastAddr) & 
                            //((state == TRANSFER_SYNC) | 
                             ((state == SEND_INIT_PARAMS) | 
                             (state == SEND_PIXEL_LOC) | 
                             (state == SEND_DATA));
        end
    end


    always_ff @ (posedge clk)
    begin
        if (reset)
        begin
            state <= INIT;
            delayTicks <= 'b0;
            lastAddr <= NUM_INIT_PARAMS;
            tftDataCmd <= 'b0;
            tftReset <= 'b1;
            tftChipSelect <= 'b1;
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    /// Load starting byte of parallel bus data. 
                    memVal <= initParamData[7:0];
                    tftDataCmd <= ~initParamData[8];
                    /// Pull reset low to trigger a reset, and delay before 
                    /// triggering next state.
                    tftReset <=  'b0;   
                    delayTicks <= MS_FOR_RESET;
                    state <= HOLD_RESET;
                end
                /// HOLD_RESET state not evaluated until delayTicks == 0.
                HOLD_RESET:
                begin
                    /// Pull reset up again to release.
                    tftReset <=  1'b1;   
                    /// Wait additional 120 ms.
                    delayTicks <= MS_120;  
                    state <= SEND_INIT_PARAMS;
                    //state <= TRANSFER_SYNC;
                end
/*
                TRANSFER_SYNC:
                begin
                    /// Pull reset up again to release.
                    tftReset <=  1'b1;   
                    /// Send a Command.
                    tftDataCmd <= 1'b0;
                    memVal <= 8'b0;
                    lastAddr <= 3;
                    state <= (memAddr == 3) ?
                                SEND_INIT_PARAMS:
                                TRANSFER_SYNC;
                end
*/
                /// SEND_INIT_PARAMS state not evaluated until delayTicks == 0.
                SEND_INIT_PARAMS:        
                begin
                    /// Keep reset high
                    tftReset <=  1'b1;   
                    /// Initialize transmission with ILI9341.
                    tftChipSelect <= 'b0;
                    memVal <= initParamData[7:0];
                    tftDataCmd <= ~initParamData[8];
                    lastAddr <= NUM_INIT_PARAMS;
                    state <= (memAddr == NUM_INIT_PARAMS) ?
                                WAIT_TO_SEND :
                                SEND_INIT_PARAMS;
                end
                WAIT_TO_SEND:
                begin
                    /// Keep reset high
                    tftReset <=  'b1;   
                    /// Cease transmission with ILI9341.
                    tftChipSelect <= 'b1;
                    delayTicks <= MS_120;
                    state <= SEND_PIXEL_LOC;
                end
                SEND_PIXEL_LOC:        
                begin
                    /// Keep reset high
                    tftReset <=  'b1;   
                    /// Reinitialize transmission with ILI9341.
                    tftChipSelect <= 'b0;
                    memVal <= pixelLocData[7:0];
                    tftDataCmd <= ~pixelLocData[8];
                    lastAddr <= NUM_FRAME_START_PARAMS;
                    state <= (memAddr == NUM_FRAME_START_PARAMS) ? 
                                SEND_DATA :
                                SEND_PIXEL_LOC;
                end
                SEND_DATA:        
                begin
                    /// Keep reset high
                    tftReset <=  'b1;   
                    memVal <= pixelDataIn; 

                    tftDataCmd <= 1'b1;   /// Only send data from this point on
                    lastAddr <= NUM_PIXELS;
                    /// reset pixel location to beginning if strobed.
                    state <= newFrameStrobe ?
                                SEND_PIXEL_LOC :
                                (memAddr == NUM_PIXELS) ? 
                                    DONE:
                                    SEND_DATA;
                end
                DONE:
                begin
                    /// Keep reset high
                    tftReset <=  'b1;   
                    state <= SEND_PIXEL_LOC;
                    /// Cease transmission with ILI9341.
                    tftChipSelect <= 'b1;
                end
                //default: state <= INIT;
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
            /// delayTicks only decrements if it is nonzero.
    end


/// Logic block for incrementing pixelAddr (via memAddr) and setting data on 
/// parallel port to ILI9341 via the 8080 I interface.
    always_ff @ (posedge clk)
    begin
        if (reset | resetMemAddr | delayTicks | newFrameStrobe)
        begin
            memAddr <= 8'b0;
            tftWriteEnable <= 1'b1;
            MSB <= 1'b0;
        end
        else if ((state == SEND_INIT_PARAMS) | (state == SEND_PIXEL_LOC) | 
                 ((state == SEND_DATA) & dataReady))    
        begin
            tftWriteEnable <= ~tftWriteEnable;
            if (tftWriteEnable)
            begin
            /// simultaneously: 
            ///     bring writeEnable low (handled above)
            ///     load data onto parallel port
/// FIXME: adding in the register tftParallelPort delays the output by one 
/// additional register, which is bad...
                tftParallelPort <= (MSB & (state == SEND_DATA)) ? 
                                       memVal[15:8] :
                                       memVal[7:0];    
            end
            else begin
            /// then:
            ///      bring writeEnable high again (handled above).
            /// toggle whether or not upper or lower pixel bits are being sent.
                MSB <= ~MSB;
    
            /// Only increment to next mem address every two bytes when sending
            /// pixel data; otherwise, increment mem address once per transfer.
                memAddr <= (state == SEND_DATA) ?
                               (MSB) ?
                                   memAddr + 8'b1 :
                                   memAddr        :
                               memAddr + 8'b1 ;
            end
        end
        else
        begin
            tftWriteEnable <= 'b1;
        end
    end
endmodule



module initParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_MCU_Parallel_Ctrl/memData.mif) *) logic [8:0] mem [0:94];
    assign memData = mem[memAddress];

endmodule


module pixelStartParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_MCU_Parallel_Ctrl/pixelStartParams.mif) *) logic [8:0] mem [0:11];
    assign memData = mem[memAddress];

endmodule


module pixelData(  input logic [16:0] memAddress,
                   output logic [15:0] memData);

    (* ram_init_file = "pixelData.mif" *) logic [15:0] mem [0:76799];
    assign memData = mem[memAddress];
endmodule



                                                                                
module clkDiv( input logic clk, reset,                                          
               input logic [7:0] divInput,      // clock divisor                
              output logic slowClk);                                            
                                                                                
    logic [7:0] divisor;    /// divisor (aka: divInput) should never be 0.         
    logic countMatch;                                                           
    logic [7:0] count;                                                          
                                                                                
    assign countMatch = (divisor == count);                                     
                                                                                
    always_ff @ (posedge clk)                                                   
    begin                                                                       
        divisor <= divInput;                                                    
    end                                                                         
                                                                                
    always_ff @ (posedge clk)                                                   
    begin                                                                       
        if (reset | countMatch )  // count reset must be synchronous.           
            count <= 8'b00000000;                                               
        else                                                                    
            count <= count + 8'b00000001;                                       
    end                                                                         
                                                                                
    always_ff @ (posedge clk, posedge reset)                                    
    if (reset)                                                                  
            slowClk <= 'b0;                                                     
    else                                                                        
    begin                                                                       
            slowClk <= (countMatch) ?                                           
                            ~slowClk :                                          
                            slowClk;                                            
    end                                                                         
endmodule                           
