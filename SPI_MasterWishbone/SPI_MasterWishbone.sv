/**
 * SPI_MasterWishbone
 * Joshua Vasquez
 * November 21, 2014
 */


/*
 * \note more cs signals may be added with small changes to the wishboneCtrl
 *       module
 */
module SPI_MasterWishbone #(NUM_CHIP_SELECTS = 3, SPI_CLK_DIV = 4)
                         ( input logic CLK_I, WE_I, STB_I, RST_I, miso,
                           input logic [7:0] ADR_I,
                           input logic [7:0] DAT_I,
                          output logic ACK_O, RTY_O,
                          output logic [7:0] DAT_O,
                          output logic [NUM_CHIP_SELECTS - 1:0] chipSelects,
                          output logic mosi, sck);

    logic setNewData;
    logic writeEnable;

    logic [7:0] dataReceived;
    logic [7:0] dataToSend;
    logic [7:0] clkDiv;


    assign DAT_O = dataReceived;

    wishboneCtrl #(.NUM_CHIP_SELECTS (NUM_CHIP_SELECTS), 
                   .SPI_CLK_DIV(SPI_CLK_DIV)) 
                 wishboneCtrlInst(
                                  .CLK_I(CLK_I), .WE_I(WE_I), .STB_I(STB_I),
                                  .RST_I(RST_I), .ADR_I(ADR_I), .DAT_I(DAT_I),
                                  .spiIdle(setNewData),
                                  .sck(sck),
                                  .chipSelects(chipSelects),
                                  .spiDataToSend(dataToSend), 
                                  .ACK_O(ACK_O), .RTY_O(RTY_O));

 
    dataCtrl dataCtrlInst(.cs(cs), .sck(sck), .writeEnable(writeEnable),
                          .spiDataIn( ),
                          .setNewData(setNewData), .addressOut( ));

    spiSendReceive spiInst(.cs(cs), .sck(slowClk), .serialDataIn(miso), 
                    .setNewData(setNewData),
                    .dataToSend(dataToSend), .serialDataOut(mosi), 
                    .dataReceived(dataReceived));  

endmodule


module wishboneCtrl #(NUM_CHIP_SELECTS = 8, SPI_CLK_DIV = 4)
                    ( input logic CLK_I, WE_I, STB_I, RST_I,
                      input logic [7:0] ADR_I,
                      input logic [7:0] DAT_I, 
                      input logic spiIdle,
                     output logic sck,
                     output logic [NUM_CHIP_SELECTS-1:0] chipSelects, 
                     output logic [7:0] spiDataToSend, 
                     output logic ACK_O,
                     output logic RTY_O);

    /// macro for the right-size decoder using "ceiling log2" function:
    parameter ADDRESS_WIDTH = $clog2(NUM_CHIP_SELECTS);

    logic slowClk;
    logic sendData;

    clkDiv clkDivInst( .clk(CLK_I), .reset(RST_I),
                       .divInput(SPI_CLK_DIV), .slowClk(slowClk));

    typedef enum logic [1:0] {STANDBY, ONE_CLK_DELAY, TRANSMITTING} stateType;

    stateType state, nextState;

/**
 * \brief sendData logic. sendData sets at the start of a wishbone transmission
 *        and clears when the spi bus starts transmitting.
 * \details if STB_I and WE_I are asserted when FSM is ready, sendData is 
 *          asserted.
 */
    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
            sendData <= 1'b0;
        else
            sendData <= (STB_I & WE_I & 
                         ((state == STANDBY) | (state == ONE_CLK_DELAY))) ? 
                            1'b1 :
                            (state == TRANSMITTING) ? 
                                1'b0:
                                sendData;
    end


/**
 * \brief chipSelects logic
 */
    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
            // All chipSelect pins should default to high
            chipSelects[ADDRESS_WIDTH - 1: 0] <= 1'b1;
        else
        begin
            // Either keep the same value 
            chipSelects[ADR_I[ADDRESS_WIDTH - 1:0]] <= 
                                (state == STANDBY) ? 
                                    1'b0 : 
                                    chipSelects[ADR_I[ADDRESS_WIDTH - 1:0]];
        end
    end


/**
 * \brief state machine logic
 */
    always_ff @ (posedge CLK_I)
    begin
        if (RST_I)
        begin   
            sck <= 1'b0; 
            spiDataToSend <= 8'b00000000;
            ACK_O <= 1'b0;
            RTY_O <= 1'b0;
            state <= STANDBY;
        end
        else 
        begin
            sck <= (state == TRANSMITTING) ? 
                        slowClk :
                        1'b0;
            RTY_O <= (state == STANDBY); 

            case (state)
                STANDBY: state <= (STB_I & WE_I) ?
                                        ONE_CLK_DELAY :
                                        STANDBY;
                ONE_CLK_DELAY:  state <= (sendData) ?
                                             TRANSMITTING:
                                             STANDBY;
                TRANSMITTING:   state <= (spiIdle)?
                                                ONE_CLK_DELAY :
                                                TRANSMITTING;
            endcase
        end
    end

endmodule



module clkDiv( input logic clk, reset, 
               input logic [7:0] divInput,      // clock divisor
              output logic slowClk);

    logic [7:0] divisor;
    logic countMatch;
    logic [7:0] count;

    assign countMatch = (divisor == count);

    always_ff @ (posedge clk)
    begin
        if (reset)
            divisor <= 8'b00000001;
        //else if (enable)
        else
            divisor <= divInput;
    end
    
    always_ff @ (posedge clk)
    begin
        if (reset | countMatch )  // count reset must be synchronous.
            count <= 8'b00000000;
        //else if (enable)
        else
            count <= count + 8'b00000001;
    end

    always_ff @ (posedge clk)
    begin
        //if (enable)
        //begin
            slowClk <= (countMatch) ? 
                            ~slowClk : 
                            slowClk;
        //end
    end

endmodule
