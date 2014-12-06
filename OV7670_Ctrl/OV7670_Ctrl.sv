/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014
 */


module OV7670_Ctrl( input logic clk, reset,
                   output logic sda, 
                   output logic scl);
                                 
    logic i2cClk, i2cReset;
    logic [7:0] memAddr;
    logic [8:0] memData;
    logic done;
    logic [7:0] dataToSend;

    OV7670_Driver OV7670_DriverInst( .clk(clk), .reset(reset),
                                         .i2cDataSent(done),
                                         .memData(memData),
                                         .dataToSend(dataToSend),
                                         .i2cClk(i2cClk), .i2cReset(i2cReset),
                                         .memAddr(memAddr));

    I2C_Guts I2C_GutsInst(.clk(i2cClk), .reset(i2cReset),
                          .dataToSend(dataToSend),
                          .sda(sda), .scl(scl),
                          .done(done));

    initParams initParamsInst(.memAddress(memAddr),
                              .memData(memData));
endmodule


/**
 * \brief the main logic block containing the finite-state machine to interact 
 *        with the camera.
 */
module OV7670_Driver(input logic clk, reset,
                     input logic i2cDataSent,
                     input logic [8:0] memData,
                    output logic [7:0] dataToSend,
                    output logic i2cClk, i2cReset,
                    output logic [7:0] memAddr);     // is it really [8:0]?

    parameter LAST_INIT_PARAM_ADDR = 86;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter RESET_TIME = 6000000; // 120 MS in clock ticks at 50 MHz


    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);

    logic resetMemAddr;

    typedef enum logic [2:0] {INIT, I2C_DONE, I2C_BUSY, INIT_COMPLETE} 
                              stateType;

    stateType state;


    always_ff @ (posedge clk)
    begin
        if (reset)
        begin
            state <= INIT;
            delayTicks <= 'b0;
            i2cReset <= 'b1;
            memAddr <= 'b0;
            //lastAddr <= LAST_INIT_PARAM_ADDR;
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    delayTicks <= RESET_TIME;
                    state <= I2C_DONE;
                end
                I2C_DONE:
                begin
                    memAddr <= memAddr + 'b1;
                    dataToSend <= memData[7:0];
                    state <= (memAddr == LAST_INIT_PARAM_ADDR) ? 
                                INIT_COMPLETE:
                                I2C_BUSY;
                end
                I2C_BUSY:        
                begin
                    /// Reset when data has been sent.
                    i2cReset <= i2cDataSent ?
                                    'b1 : 'b0;

                    //lastAddr <= LAST_PIX_DATA_ADDR;
                    state <= i2cDataSent ?
                                I2C_DONE :
                                I2C_BUSY;
                end
                INIT_COMPLETE:
                    state <= INIT_COMPLETE;
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
    end
endmodule



/**
 * \brief contains settings to send to camera
 * \details MSbit indicates end of a single transfer
 */
module initParams(  input logic [6:0] memAddress,
                   output logic [8:0] memData); 

    (* ram_init_file = "memData.mif" *) logic [8:0] mem [0:88];
    assign memData = mem[memAddress];

endmodule
