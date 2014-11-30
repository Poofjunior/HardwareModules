/**
 * ILI9341_Ctrl
 * Joshua Vasquez
 * November 23 - 30, 2014
 */


/*
 * \note more cs signals may be added with small changes to the wishboneCtrl
 *       module
 */
module ILI9341_Ctrl( input logic CLK_I, WE_I, STB_I, RST_I,
                     input logic [7:0] ADR_I,
                     input logic [7:0] DAT_I,
                    output logic ACK_O, RTY_O,
                    output logic [7:0] DAT_O,
                    output logic tftChipSelect, tftMosi, tftSck, tftReset);

    parameter LAST_INIT_PARAM_ADDR = 86;
    parameter LAST_PIX_LOC_ADDR = 11;
    parameter LAST_PIX_DATA_ADDR = 76800;
    parameter MS_120 = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter MS_FOR_RESET = 10000000;  // delay time in clock ticks for reset

    parameter ROWS_ = 320;
    parameter COLS_ = 240;


    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);

    logic dataSent; // indicates when to load new data onto SPI bus.

    logic [16:0] memAddr;
    logic [16:0] lastAddr;

    logic [7:0] initParamData;
    logic [7:0] pixelLocData;
    logic [7:0] pixelData;

    logic resetMemAddr;


    initParams initParamsInst(.memAddress(memAddr[6:0]),
                              .memData(initParamData));
    pixelLocParams pixelLocParamsInst(.memAddress(memAddr[6:0]),
                              .memData(pixelLocData));
    pixelData pixelDataInst(.memAddress(memAddr),
                              .memData(pixelData));

    logic spiWriteEnable;
    logic spiStrobe;
    logic spiBusy;
    logic spiAck;
    logic [7:0] spiChipSelect;
    logic [7:0] spiDataToSend;
    logic [7:0] memVal;

    SPI_MasterWishbone #(.NUM_CHIP_SELECTS(1), .SPI_CLK_DIV(0))
                SPI_MasterWishboneInst( .CLK_I(CLK_I), .WE_I(spiWriteEnable),
                                        .STB_I(spiStrobe), .RST_I(RST_I),
                                        .miso(), .ADR_I(spiChipSelect),
                                        .DAT_I(spiDataToSend),
                                        .ACK_O(spiAck),
                                        .RTY_O(spiBusy), .DAT_O(), 
                                        .chipSelects(tftChipSelect),
                                        .mosi(tftMosi), .sck(tftSck));
                                        

/// TODO: implement two more RAMS: one for pixel-start transmissions, and one
//        for actual pixel data.


    typedef enum logic [2:0] {INIT, HOLD_RESET, SEND_INIT_PARAMS, WAIT_TO_SEND,
                              SEND_PIXEL_LOC, SEND_DATA} 
                             stateType;
    stateType state;


    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
        begin
            resetMemAddr <= 'b1;
        end
        else 
        begin
            resetMemAddr <= (memAddr == lastAddr) & 
                            ((state == SEND_INIT_PARAMS) | 
                             (state == SEND_PIXEL_LOC) | 
                             (state == SEND_DATA) ); 
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
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    /// set address 0 and no CSHOLD
                    spiChipSelect <= 'h0;   
                    /// load starting byte of SPI data. 
                    memVal <= initParamData;

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
                    memVal <= initParamData;
                    lastAddr <= LAST_INIT_PARAM_ADDR;
                    state <= (memAddr == lastAddr) ?
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
                    memVal <= pixelLocData;
                    lastAddr <= LAST_PIX_LOC_ADDR;
                    state <= (memAddr == lastAddr) ? 
                                SEND_DATA :
                                SEND_PIXEL_LOC;
                end
                SEND_DATA:        
                begin
                    memVal <= pixelData;
                    lastAddr <= LAST_PIX_DATA_ADDR;
                    state <= SEND_DATA;
                end
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
    end


    always_ff @ (posedge CLK_I)
    begin
        if (RST_I | resetMemAddr | delayTicks)
        begin
            memAddr <= 'b0;
            spiStrobe <= 'b0;
            spiWriteEnable <= 'b0;
            dataSent <= 'b0;
        end
        else if ((state == SEND_INIT_PARAMS) | (state == SEND_PIXEL_LOC) | 
                 (state == SEND_DATA)) 
        begin
            if (~spiBusy)
            begin
                // Enable WE_I and STB_I signals.
                spiStrobe <= 'b1; 
                spiWriteEnable <= 'b1; 
    
                // Load next byte of SPI data. 
                spiDataToSend <= memVal;
    
                dataSent <= 'b1;
    
            end
            else
            begin
                // Pull down WE_I and STB_I signals.
                spiStrobe <= 'b0;
                spiWriteEnable <= 'b0;
    
                // Increment to next mem address once.
                memAddr <= (dataSent) ? 
                                    memAddr + 'b1:
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
                   output logic [7:0] memData);

    (* ram_init_file = "memData.mif" *) logic [7:0] mem [0:88];
    assign memData = mem[memAddress];

endmodule


module pixelLocParams(  input logic [6:0] memAddress,
                   output logic [7:0] memData);

    (* ram_init_file = "pixelLocParams.mif" *) logic [7:0] mem [0:10];
    assign memData = mem[memAddress];

endmodule

/// FIXME: memAddress should be larger than 
module pixelData(  input logic [16:0] memAddress,
                   output logic [7:0] memData);

    (* ram_init_file = "pixelData.mif" *) logic [7:0] mem [0:76799];
    assign memData = mem[memAddress];

endmodule
