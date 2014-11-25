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
                    output logic tftChipSelect, tftMosi, tftSck);

    parameter TOTAL_INIT_PARAMS = 89;
    parameter MS_120 = 6000000;

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
    SPI_MasterWisbhone #(.NUM_CHIP_SELECTS(1), .SPI_CLK_DIV(4))
                SPI_MasterWishboneInst( .CLK_I(CLK_I), .WE_I(spiWriteEnable),
                                        .STB_I(spiStrobe), .RST_I(RST_I),
                                        .miso(), .ADR_I(spiChipSelect),
                                        .DAT_I(spiDataToSend),
                                        .ACK_O(spiAck),
                                        .RTY_O(spiBusy), .DAT_O(), 
                                        .chipSelects(tftChipSelect),
                                        .mosi(tftMosi), .tftSck(sck));
                                        

    typedef enum logic [1:0] {INIT, SEND_INIT_PARAMS, SEND_DATA} stateType;

    always_ff @ (posedge clk)
    begin
        if (reset)
            state <= INIT;
            initParamAddr <= 'b0;
            delayTicks <= 'b0;
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    spiDataToSend <= initParamAddr;
                    state <= SEND_INIT_PARAMS;
                    spiChipSelect <= 'h0;   /// address 0 and no CSHOLD
                end
                SEND_INIT_PARAMS:        
                begin
                    if (~spiBusy)
                    begin
                        spiStrobe <= 'b1; 
                        spiWriteEnable <= 'b1; 
                        initParamCount <= initParamCount + 'b1; // TODO: this works here?
                        initParamAddress <= initParamAddress + 'b1;
                        state <= SEND_INIT_PARAMS;
                    end
                    else
                    begin
                        stae <= (initParamCount > TOTAL_INIT_PARAMS) ?
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
        end
        else
            delayTicks <= delayTicks - 'b1;
    end
endmodule


module initParams(  input logic [6:0] memAddress,
                   output logic [7:0] memData)

    (* ram_init_file = "memData.mif" *) logic [7:0] mem [0:88];
    assign memData = mem[memAddress];

endmodule


