/**
 * ILI9341_Ctrl
 * Joshua Vasquez
 * December 24 2014 - January 5, 2015
 */
`include <filePaths.sv>


module ILI9341_MCU_Parallel_Ctrl( input logic clk, reset, 
    output logic [7:0] tftParallelPort,
    output logic tftChipSelect, tftWriteEnable, tftReset, tftDataCmd);

    logic slowClk;
    logic [15:0] pixelDataIn;   
    logic [16:0] pixelAddr; // large enough for 320*240 = 76800 pixel addresses

/// Do not wire this module to external reset because it clocks the behavior
/// of the rest of the internal logic
    clkPrescaler clkPrescalerInst(.clk(clk), .reset(1'b0), .divInput(8'b0), 
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
/// output signals to ILI9341 MCU 8080-I Parallel Interface
        output logic [7:0] tftParallelPort,
        output logic tftChipSelect, 
        output logic tftWriteEnable, 
        output logic tftReset,
 /// indicates whether parallel bus byte is cmd or data based on memory values
        output logic tftDataCmd); 

/// Custom "stateType" for the Finite-State Machine
    typedef enum logic [3:0] {INIT, TRANSFER_SYNC, TRANSFER_SYNC_DELAY, 
                              HOLD_RESET, ENABLE_DISPLAY, ENABLE_DISPLAY_DELAY,
                              SEND_INIT_PARAMS, WAIT_TO_SEND, SEND_PIXEL_LOC, 
                              SEND_DATA, DONE} 
                             stateType;


/// ---- BEGIN: CONSTANTS ----
/// number of values in the memory containing all of the initialization values
    parameter NUM_INIT_PARAMS = 29;

/// number of values in the memory containing the data sent at the start of a 
/// new frame
    parameter NUM_FRAME_START_PARAMS = 11;

/// Total number of pixels.
    parameter NUM_PIXELS = 76800;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter MS_120 = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter MS_5 = 250000; // 120 MS in clock ticks at 50 MHz
    parameter MS_FOR_RESET = 10000000;  // delay time in clock ticks for reset
/// ---- END: CONSTANTS ----


/// ---- BEGIN: INTERNAL LOGIC ----
    logic [24:0] delayTicks;
    logic delayOff;

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

/// indicates whether upper or lower byte of 16-bit data is being transferred
    logic MSB;

    stateType state, nextState;
///---- END: INTERNAL LOGIC ----

/// pixelAddr is basically memAddr once initialization is finished.
    assign pixelAddr = memAddr;
    assign delayOff = &(~delayTicks);



/// ---- State Register with delays at key states ----
    always_ff @ (posedge clk)
    begin
        if (reset)
        begin
            state <= INIT;
            delayTicks <= MS_FOR_RESET;
        end
        else if (delayOff)
        begin
            state <= nextState;
            case (state)
                INIT: delayTicks <= MS_FOR_RESET;
                HOLD_RESET: delayTicks <= MS_120;  
                TRANSFER_SYNC_DELAY: delayTicks <= MS_5;
                ENABLE_DISPLAY_DELAY: delayTicks <= MS_120;
                WAIT_TO_SEND: delayTicks <= MS_120;
                WAIT_TO_SEND: delayTicks <= MS_120;
            default: delayTicks <= 'b0;
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1; 
    end


/// ---- Next-State Logic ----
    always_comb
        case (state)
            INIT: nextState = HOLD_RESET;
            HOLD_RESET: nextState = TRANSFER_SYNC; 
            TRANSFER_SYNC: nextState = (memAddr == 3) ?
                                                TRANSFER_SYNC_DELAY:
                                                TRANSFER_SYNC;
            TRANSFER_SYNC_DELAY: nextState = SEND_INIT_PARAMS;  
            SEND_INIT_PARAMS: nextState = (memAddr == NUM_INIT_PARAMS) ?
                                                WAIT_TO_SEND :
                                                SEND_INIT_PARAMS;
            WAIT_TO_SEND: nextState = ENABLE_DISPLAY;
            ENABLE_DISPLAY: nextState = ENABLE_DISPLAY_DELAY;
            ENABLE_DISPLAY_DELAY: nextState = SEND_PIXEL_LOC;
            SEND_PIXEL_LOC: nextState = (memAddr == NUM_FRAME_START_PARAMS) ? 
                                            SEND_DATA :
                                            SEND_PIXEL_LOC;
            SEND_DATA: nextState =  newFrameStrobe ?
                                        SEND_PIXEL_LOC :
                                        (memAddr == NUM_PIXELS) ? 
                                            DONE:
                                            SEND_DATA;
            DONE: nextState = SEND_PIXEL_LOC; 
            default: nextState = INIT;
        endcase


//// ------------ Additional Signals --------------


/// ---- resetMemAddr Logic ----
    always_ff @ (posedge clk)
    if (reset)
        resetMemAddr = 1'b1;
    else if (memAddr == lastAddr)
        case (state)
            TRANSFER_SYNC: resetMemAddr = 1'b1;
            ENABLE_DISPLAY: resetMemAddr = 1'b1;
            SEND_INIT_PARAMS: resetMemAddr = 1'b1;
            SEND_PIXEL_LOC: resetMemAddr = 1'b1;
            SEND_DATA: resetMemAddr = 1'b1;
        default: resetMemAddr = 1'b0;
        endcase
    else 
        resetMemAddr = 1'b0;

/**
 * There are a couple of ways to write up the remaining signals. I chose to 
 * separate them into individual always_ff blocks, (rather than cramming them
 * into one always_ff block) to emphasize explicitly when a signal will
 * change, rather than how a signal changes in the context of the other
 * signals.
 *
 * I haven't completely settled on which style I like yet, but I'm following
 * Clifford E. Cummings' "Sythesizeable Finite State Machine Design Techniques 
 * Using the New System Verilog 3.0 Enhancements" Conference Paper.
 */

/// ---- lastAddr Logic ----
    always_ff @ (posedge clk)
    if (reset)
        lastAddr = NUM_INIT_PARAMS;
    else begin
        case (state)
            TRANSFER_SYNC: lastAddr = 3;
            SEND_INIT_PARAMS: lastAddr = NUM_INIT_PARAMS;
            ENABLE_DISPLAY: lastAddr = 1;
            SEND_PIXEL_LOC: lastAddr = NUM_FRAME_START_PARAMS;
            SEND_DATA: lastAddr = NUM_PIXELS;
        default: lastAddr = NUM_INIT_PARAMS;
        endcase
    end

    always_ff @ (posedge clk)
    if (reset)
        tftDataCmd = 1'b0;
    else begin
        case (state)
            INIT:   tftDataCmd = ~initParamData[8];
            TRANSFER_SYNC: tftDataCmd = 'b0;
            SEND_INIT_PARAMS:tftDataCmd <= ~initParamData[8]; 
            ENABLE_DISPLAY: tftDataCmd <= 1'b0;
            SEND_PIXEL_LOC: tftDataCmd <= ~pixelLocData[8];
            SEND_DATA: tftDataCmd <= 1'b1;   
        default: tftDataCmd <= 1'b0;
        endcase
    end

/// ---- tftReset Logic ---- 
    always_ff @ (posedge clk)
    if (reset)
        tftReset = 1'b1;
    else begin
        case (state)
            INIT:   tftReset =  'b0;   
            HOLD_RESET: tftReset =  1'b1;   
        default: tftReset = 1'b1;
        endcase
    end

/// ---- tftChipSelect Logic ---- 
    always_ff @ (posedge clk)
    if (reset)
        tftChipSelect = 1'b1;
    else begin
        case (state)
            TRANSFER_SYNC: tftChipSelect = 'b0;
            TRANSFER_SYNC_DELAY: tftChipSelect = 'b1;
            SEND_INIT_PARAMS: tftChipSelect <= 'b0;
            WAIT_TO_SEND: tftChipSelect = 1'b1;
            ENABLE_DISPLAY: tftChipSelect = 1'b0;
            ENABLE_DISPLAY_DELAY: tftChipSelect = 1'b0;
            SEND_PIXEL_LOC: tftChipSelect = 1'b0;
            SEND_DATA: tftChipSelect = 1'b0;
            DONE: tftChipSelect = 1'b1;
        default: tftChipSelect = 1'b1;
        endcase
    end


/// Logic for incrementing memAddr and strobing data on MCU parallel port
    always_ff @ (posedge clk)
    begin
        /// reset case:
        if (reset | resetMemAddr | delayTicks | newFrameStrobe)
        begin
            memAddr <= 17'b0;
            tftWriteEnable <= 1'b1;
            tftParallelPort <= 8'b0;
            MSB <= 1'b0;
        end
        else if ((state == SEND_INIT_PARAMS) | (state == SEND_PIXEL_LOC) | 
                 (state == TRANSFER_SYNC) | (state == ENABLE_DISPLAY) | 
                 ((state == SEND_DATA) & dataReady))    
        begin
            /// Toggle tftWriteEnable Signal.
            tftWriteEnable <= ~tftWriteEnable;

            if (tftWriteEnable)
            begin
            /// Simultaneously: 
            ///     bring writeEnable low (handled above)
            ///     load data onto parallel port (depending on state)
                case (state)
                    TRANSFER_SYNC:    tftParallelPort <= 8'b0;
                    SEND_INIT_PARAMS: tftParallelPort <= initParamData[7:0];
                    ENABLE_DISPLAY:   tftParallelPort <= 8'h29;
                    SEND_PIXEL_LOC:   tftParallelPort <= pixelLocData[7:0];
                    SEND_DATA:        tftParallelPort <= MSB ? 
                                                            pixelDataIn[15:8] :
                                                            pixelDataIn[7:0];    
                default: 
                    tftParallelPort <= initParamData[7:0];
                endcase
            end
            else begin
            /// Then:
            ///      bring writeEnable high again (handled above) and toggle 
            ///     whether or not upper or lower pixel bits are being sent.
                MSB <= ~MSB;

            /// Increment mem address once per parallel transfer only when
            /// sending initialization data. Otherwise, increment to next mem 
            /// address every two bytes when sending pixel data; 
                memAddr <= (state == SEND_DATA) ?
                               (MSB) ?
                                   memAddr + 17'b1 :
                                   memAddr        :
                               memAddr + 17'b1 ;
            end
        end
        else begin
            tftWriteEnable <= 'b1;
            memAddr <= memAddr;
        end
    end
endmodule



/**
 * \brief a block of SRAM for storing the sequential stream of initialization
 *        parameters.
 */
module initParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_MCU_Parallel_Ctrl/memData.mif) *) logic [8:0] mem [0:29];
    assign memData = mem[memAddress];

endmodule

/**
 * \brief a block of SRAM for storing the sequential stream of parameters sent
 *        at the start of each pixel.
 */
module pixelStartParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_MCU_Parallel_Ctrl/pixelStartParams.mif) *) logic [8:0] mem [0:10];
    assign memData = mem[memAddress];

endmodule


/**
 * \brief a temporary block of SRAM for storing the data for a single frame.
 * \note the DE0 Nano's Cyclone IV does not have enough resources to store
 *       an entire 320x240 image, so the addresses will repeat themselves.
 */
module pixelData(  input logic [16:0] memAddress,
                   output logic [15:0] memData);

    (* ram_init_file = "pixelData.mif" *) logic [15:0] mem [0:76799];
    assign memData = mem[memAddress];
endmodule



                                                                                
module clkPrescaler( input logic clk, reset,                                          
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
