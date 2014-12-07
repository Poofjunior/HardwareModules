/**
 * synthesizable guts of an i2c controller 
 * Joshua Vasquez
 * December 5, 2014
 */

/**
 * \brief an spi slave module that both receives input values and clocks out
 *        output values according to SPI Mode0.
 * \details note that the dataToSend input is sampled whenever the setNewData
 *          signal is asserted.
 *
 * \note deviceAck has not been implemented yet.
 */
module I2C_Guts(input logic clk, reset, i2cStrobe,
                input logic [7:0] dataToSend, 
                input logic lastTransfer,
               output logic sda, 
               output logic scl,
               output logic busy);
               //output logic ackDataToSend);    

    parameter NINE_BITS_OUT = 9;
    parameter BYTE_OUT = 8;
    parameter I2C_DELAY = 250;
    parameter I2C_HALF_DELAY = 125;

    logic [7:0] delayTicks;
    logic [7:0] shiftReg;
    logic [3:0] bitCount;
    logic delayOff;

    assign delayOff = &(~delayTicks);

    assign busy = (state != IDLE);

    typedef enum logic [3:0] {BEGIN_XFER_STEP1, BEGIN_XFER_STEP2, 
                              LOAD_DATA, CLK_DOWN, CLK_UP, STOP_XFER_STEP1,
                              STOP_XFER_STEP2, XFER_COMPLETE, IDLE} stateType;
    stateType state;

    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
        begin
            state <= IDLE;
            sda <= 1'b1;
            scl <= 1'b1;
            bitCount <= 'b0;
            delayTicks <= 'b0;
        end
        else if (delayOff)
        begin
            case (state)
                IDLE:
                begin
                    /// reset bitCount at the start of every new transfer.
                    bitCount <= 'b0;
                    /// keep capturing dataToSend and init transfer when
                    /// strobed.
                    shiftReg <= dataToSend;

                    state <= (i2cStrobe)? 
                                BEGIN_XFER_STEP1 :
                                IDLE;
                end 
                BEGIN_XFER_STEP1:
                begin
                    sda <= 1'b0;
                    delayTicks <= I2C_DELAY;
                    state <= BEGIN_XFER_STEP2;
                end
                BEGIN_XFER_STEP2:
                begin
                    bitCount <= 'b0;
                    scl <= 1'b0;
                    delayTicks <= I2C_DELAY;
                    state <= CLK_DOWN;
                end
                CLK_DOWN:
                begin
                    scl <= 1'b0;
                    delayTicks <= I2C_HALF_DELAY;
                    state <= LOAD_DATA;
                end
                LOAD_DATA:
                begin

                    shiftReg[7:0] <= (shiftReg[7:0] << 1);
                    sda <= (bitCount == BYTE_OUT) ? 
                                1'bz :
                                (bitCount == NINE_BITS_OUT) ?
                                    1'b0 :
                                    shiftReg[7];

                    delayTicks <= I2C_HALF_DELAY;
                    state <= (bitCount == NINE_BITS_OUT)?
                                (lastTransfer) ?
                                    STOP_XFER_STEP1  :  /// send i2c stop sig.
                                    XFER_COMPLETE:      /// get new data.
                                CLK_UP;                 /// continue transfer.
                end
                CLK_UP:
                begin
                    bitCount <= bitCount + 1'b1;
                    scl <= 1'b1;

                    delayTicks <= I2C_DELAY;
                    state <= CLK_DOWN;
                end
                STOP_XFER_STEP1:
                begin
                    scl <= 1'b1;
                    bitCount <= 'b0;
                    delayTicks <= I2C_DELAY;
                    state <= STOP_XFER_STEP2;
                end
                STOP_XFER_STEP2:
                begin
                    sda <= 1'b1;
                    delayTicks <= I2C_DELAY;
                    state <= XFER_COMPLETE;
                end
                XFER_COMPLETE:
                    state <= IDLE;
                default: state <= IDLE;
            endcase
        end
        else
            delayTicks <= delayTicks - 1'b1;
    end

endmodule
