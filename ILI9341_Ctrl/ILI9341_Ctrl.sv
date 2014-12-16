/**
 * ILI9341_Ctrl
 * Joshua Vasquez
 * November 23 - December 3, 2014
 */
`include <filePaths.sv>


module ILI9341_Ctrl( input logic CLK_I, RST_I, 
                    output logic tftChipSelect, tftMosi, tftSck, tftReset, 
                                 dataCtrl);

    logic [15:0] pixelDataIn;   
    logic [16:0] pixelAddr; // large enough for 320*240 = 76800 pixel addresses



    ILI9341_Driver driverInst( .CLK_I(CLK_I), .RST_I(RST_I),
                               .initPixelStrobe(1'b0), 
                               .dataReady(1'b1),
                                .pixelDataIn(pixelDataIn), 
                               .pixelAddr(pixelAddr),
                               .tftChipSelect(tftChipSelect), 
                               .tftMosi(tftMosi),
                               .tftSck(tftSck),
                               .tftReset(tftReset),
                               .dataCtrl(dataCtrl));

    pixelData pixelDataInst( .memAddress(pixelAddr), .memData(pixelDataIn)); 
endmodule


/**
 * \brief the main logic block containing the finite-state machine to drive
 *        the display. Display settings are stored in ram internal to this 
 *        module.
 */
module ILI9341_Driver(input logic CLK_I, RST_I,
                      input logic initPixelStrobe, 
                      input logic dataReady,     /// controls when pixelDataIn
                                                 /// is output on SPI bus.
                      input logic [15:0] pixelDataIn,
                     output logic [16:0] pixelAddr,
                     output logic tftChipSelect, tftMosi, tftSck, tftReset,
                                 dataCtrl); 

    parameter LAST_INIT_PARAM_ADDR = 86;
    parameter LAST_PIX_LOC_ADDR = 11;
    parameter LAST_PIX_DATA_ADDR = 76800;
    parameter ROWS_ = 320;
    parameter COLS_ = 240;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter MS_120 = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter MS_FOR_RESET = 10000000;  // delay time in clock ticks for reset



    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);

    logic dataSent; // indicates when to load new data onto SPI bus.

    logic [16:0] memAddr;
    logic [16:0] lastAddr;

    logic [8:0] initParamData;  // Bit 8 indicates command or data on SPI bus
    logic [8:0] pixelLocData;

    logic [7:0] pixelData;

    logic resetMemAddr;
    logic dataOrCmd;    // indicates whether byte on SPI bus is a cmd or data.


    initParams initParamsInst(.memAddress(memAddr[6:0]),
                              .memData(initParamData));
    pixelLocParams pixelLocParamsInst(.memAddress(memAddr[6:0]),
                              .memData(pixelLocData));

    logic spiWriteEnable;
    logic spiStrobe;
    logic spiBusy;
    logic spiAck;

    logic [7:0] spiChipSelect;

    logic [15:0] memVal; // value read from any of the given memory blocks 
                        // that is to be written out over SPI.
    logic [7:0] spiDataToSend;  // value to be sent out over SPI protocol.

    logic MSB;

    SPI_MasterWishbone #(.NUM_CHIP_SELECTS(1), .SPI_CLK_DIV(0))
                SPI_MasterWishboneInst( .CLK_I(CLK_I), .WE_I(spiWriteEnable),
                                        .STB_I(spiStrobe), .RST_I(RST_I),
                                        .miso(), .ADR_I(spiChipSelect),
                                        .DAT_I(spiDataToSend),
                                        .ACK_O(spiAck),
                                        .RTY_O(spiBusy), .DAT_O(), 
                                        .chipSelects(tftChipSelect),
                                        .mosi(tftMosi), .sck(tftSck));
                                        
    assign pixelAddr = memAddr;

    typedef enum logic [2:0] {INIT, HOLD_RESET, SEND_INIT_PARAMS, WAIT_TO_SEND,
                              SEND_PIXEL_LOC, SEND_DATA, DONE} 
                             stateType;
    stateType state;


/// Logic for resetMemAddr
    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
        begin
            resetMemAddr <= 'b1;
        end
        else 
        begin
            // resetMemAddr is the signal to reset mem address location to 0 
            // each time the current block of data has finished writing for 
            // the given states.
            resetMemAddr <= (memAddr == lastAddr) & 
                            ((state == SEND_INIT_PARAMS) | 
                             (state == SEND_PIXEL_LOC) | 
                             (state == SEND_DATA));
        end
    end


    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
        begin
            state <= INIT;
            delayTicks <= 'b0;
            tftReset <= 'b1;
            lastAddr <= LAST_INIT_PARAM_ADDR;
            dataOrCmd <= 'b0;
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    /// set address 0 and no CSHOLD
                    spiChipSelect <= 'h0;   
                    /// load starting byte of SPI data. 
                    memVal <= initParamData[7:0];
                    dataOrCmd <= initParamData[8];
                    tftReset <=  'b0;   // pull reset low to trigger.
                    delayTicks <= MS_FOR_RESET;
                    state <= HOLD_RESET;
                end
                HOLD_RESET:
                begin
                    tftReset <=  'b1;   // pull reset up again to release.
                    delayTicks <= MS_120;   // wait additional 120 ms.
                    state <= SEND_INIT_PARAMS;
                end
                SEND_INIT_PARAMS:        
                begin
                    memVal <= initParamData[7:0];
                    dataOrCmd <= initParamData[8];
                    lastAddr <= LAST_INIT_PARAM_ADDR;
                    state <= (memAddr == LAST_INIT_PARAM_ADDR) ?
                                WAIT_TO_SEND :
                                SEND_INIT_PARAMS;
                end
                WAIT_TO_SEND:
                begin
                    delayTicks <= MS_120;
                    state <= SEND_PIXEL_LOC;
                end
                SEND_PIXEL_LOC:        
                begin
                    memVal <= pixelLocData[7:0];
                    dataOrCmd <= pixelLocData[8];
                    lastAddr <= LAST_PIX_LOC_ADDR;
                    state <= (memAddr == LAST_PIX_LOC_ADDR) ? 
                                SEND_DATA :
                                SEND_PIXEL_LOC;
                end
                SEND_DATA:        
                begin
                    memVal <= pixelDataIn; 

                    dataOrCmd <= 'b0;   /// Only send data from this point on
                    lastAddr <= LAST_PIX_DATA_ADDR;
                    /// reset pixel location to beginning if strobed.
                    state <= initPixelStrobe ?
                                SEND_PIXEL_LOC :
                                (memAddr == LAST_PIX_DATA_ADDR) ? 
                                    DONE:
                                    SEND_DATA;
                end
                DONE:
                begin
                    state <= SEND_PIXEL_LOC;
                end
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
    end


/// Logic block for incrementing pixelAddr (via memAddr) and low-level
/// signals to SPI module.
    always_ff @ (posedge CLK_I)
    begin
        if (RST_I | resetMemAddr | delayTicks | initPixelStrobe)
        begin
            memAddr <= 'b0;
            spiStrobe <= 'b0;
            spiWriteEnable <= 'b0;
            dataSent <= 'b0;
            dataCtrl <= 'b0;
            MSB <= 'b0;
        end
        else if ((state == SEND_INIT_PARAMS) | (state == SEND_PIXEL_LOC) | 
                 ((state == SEND_DATA) & dataReady))    // dataReady is href 
        begin
            if (~spiBusy)
            begin
                // Enable WE_I and STB_I signals to signal start of SPI
                // trasnfer.
                spiStrobe <= 'b1; 
                spiWriteEnable <= 'b1; 
    
                // Load next byte of SPI data. 
                // Should remain at lower byte only for initial data and then 
                // toggle between lower and upper bytes.
                spiDataToSend <= (MSB & (state == SEND_DATA)) ? 
                                    memVal[15:8] :
                                    memVal[7:0];    
    
                dataCtrl <= ~dataOrCmd;
                dataSent <= 'b1;
            end
            else
            begin
                // Pull down WE_I and STB_I signals.
                spiStrobe <= 'b0;
                spiWriteEnable <= 'b0;

                // toggle whether or not MSB is being sent.
                MSB <= ~MSB;
    
                // Increment to next mem address once when data is sent and
                // increment to next mem address every two bytes when sending
                // pixel data.
                memAddr <= (dataSent) ? 
                                (state == SEND_DATA) ?
                                    (MSB) ?
                                        memAddr + 'b1 :
                                        memAddr             :
                                    memAddr + 'b1 :
                                memAddr;

                dataSent <= 'b0;
            end
        end
        else
        begin
            spiStrobe <= 'b0;
            spiWriteEnable <= 'b0;
            dataSent <= 'b0;
        end
    end
endmodule



module initParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_Ctrl/memData.mif) *) logic [8:0] mem [0:88];
    assign memData = mem[memAddress];

endmodule


module pixelLocParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData);

    (* ram_init_file = `HARDWARE_MODULES_DIR(ILI9341_Ctrl/pixelLocParams.mif) *) logic [8:0] mem [0:10];
    assign memData = mem[memAddress];

endmodule


module pixelData(  input logic [16:0] memAddress,
                   output logic [15:0] memData);

    (* ram_init_file = "pixelData.mif" *) logic [15:0] mem [0:76799];
    assign memData = mem[memAddress];
endmodule
