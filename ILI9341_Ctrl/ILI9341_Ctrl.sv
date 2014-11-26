/**
 * ILI9341_Ctrl
 * Joshua Vasquez
 * November 23, 2014
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

    parameter LAST_INIT_PARAM_ADDR = 89;
    parameter MS_120 = 6000000;
    parameter MS_FOR_RESET = 10000000;

    logic [23:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);

    logic [6:0] initParamAddr;
    logic [7:0] initParamData;


    initParams initParamsInst(.memAddress(initParamAddr),
                              .memData(initParamData));

    logic spiWriteEnable;
    logic spiStrobe;
    logic spiBusy;
    logic spiAck;
    logic [7:0] spiChipSelect;
    logic [7:0] spiDataToSend;
    SPI_MasterWishbone #(.NUM_CHIP_SELECTS(1), .SPI_CLK_DIV(4))
                SPI_MasterWishboneInst( .CLK_I(CLK_I), .WE_I(spiWriteEnable),
                                        .STB_I(spiStrobe), .RST_I(RST_I),
                                        .miso(), .ADR_I(spiChipSelect),
                                        .DAT_I(spiDataToSend),
                                        .ACK_O(spiAck),
                                        .RTY_O(spiBusy), .DAT_O(), 
                                        .chipSelects(tftChipSelect),
                                        .mosi(tftMosi), .sck(tftSck));
                                        

    typedef enum logic [2:0] {INIT, HOLD_RESET, SEND_INIT_PARAMS, WAIT_TO_SEND,
                              SEND_DATA} 
                             stateType;
    stateType state;

    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
        begin
            state <= INIT;
            initParamAddr <= 'b0;
            delayTicks <= 'b0;
            tftReset <= 'b1;
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    /// set address 0 and no CSHOLD
                    spiChipSelect <= 'h0;   
                    /// load starting byte of SPI data. 
                    spiDataToSend <= initParamData;

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
                    if (~spiBusy)
                    begin
                        // Enable WE_I and STB_I signals.
                        spiStrobe <= 'b1; 
                        spiWriteEnable <= 'b1; 

                        state <= SEND_INIT_PARAMS;
                    end
                    else
                    begin
                        // Pull down WE_I and STB_I signals.
                        spiStrobe <= 'b0;
                        spiWriteEnable <= 'b0;

                        // Load next byte of SPI data. 
                        spiDataToSend <= initParamData;

                        // Increment to next initParam address
                        initParamAddr <= initParamAddr + 'b1;

                        state <= (initParamAddr > LAST_INIT_PARAM_ADDR) ?
                                    WAIT_TO_SEND:
                                    SEND_INIT_PARAMS; 
                    end
                end
                WAIT_TO_SEND:
                begin
                    delayTicks <= MS_120;
                    state <= SEND_DATA;
                end
                SEND_DATA:        
                    state <= SEND_DATA;
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
    end
endmodule


module initParams(  input logic [6:0] memAddress,
                   output logic [7:0] memData);

    (* ram_init_file = "memData.mif" *) logic [7:0] mem [0:88];
    assign memData = mem[memAddress];

endmodule


