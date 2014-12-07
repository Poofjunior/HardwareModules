/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014
 */


module OV7670_Ctrl( input logic clk, reset,
                   output logic sda, 
                   output logic scl);
                                 
    logic i2cClk, i2cStrobe;
    logic [7:0] memAddr;
    logic [8:0] memData;
    logic busy, lastTransfer;
    logic [7:0] dataToSend;

    OV7670_Driver OV7670_DriverInst( .clk(clk), .reset(reset),
                                         .i2cBusy(busy),
                                         .memData(memData),
                                         .dataToSend(dataToSend),
                                         .i2cStrobe(i2cStrobe),
                                         .lastTransfer(lastTransfer),
                                         .memAddr(memAddr));

    I2C_Guts I2C_GutsInst(.clk(clk), .reset(reset),
                          .i2cStrobe(i2cStrobe),
                          .dataToSend(dataToSend),
                          .lastTransfer(lastTransfer),
                          .sda(sda), .scl(scl),
                          .busy(busy));

    initParams initParamsInst(.memAddress(memAddr),
                              .memData(memData));
endmodule


/**
 * \brief the main logic block containing the finite-state machine to interact 
 *        with the camera.
 */
module OV7670_Driver(input logic clk, reset,
                     input logic i2cBusy,
                     input logic [8:0] memData,
                    output logic [7:0] dataToSend,
                    output logic i2cStrobe, lastTransfer,
                    output logic [7:0] memAddr);     // is it really [8:0]?

    parameter LAST_INIT_PARAM_ADDR = 86;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter RESET_TIME = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter DELAY_ONE = 10; 

    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);

    logic resetMemAddr;




    typedef enum logic [2:0] {INIT, I2C_DONE, I2C_BUSY, INIT_COMPLETE} 
                              stateType;

    stateType state;


    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
        begin
            state <= INIT;
            delayTicks <= 'b0;
            memAddr <= 'b0;
            lastTransfer <= memData[8];
            i2cStrobe <= 'b0;
            delayTicks <= 'b0;
        end
        else if (delayOff) 
        begin
            case (state)
                INIT: 
                begin
                    delayTicks <= RESET_TIME;
                    state <= I2C_DONE;
                    dataToSend <= memData[7:0]; /// load first byte only
                end
                I2C_DONE:
                begin
                    delayTicks <= DELAY_ONE;
                    i2cStrobe <= (memAddr == LAST_INIT_PARAM_ADDR)?
                                    1'b0 :
                                    1'b1;
    
                    memAddr <= memAddr + 'b1;
                    lastTransfer <= memData[8];
                    dataToSend <= memData[7:0];
                    state <= (memAddr == LAST_INIT_PARAM_ADDR) ? 
                                INIT_COMPLETE:
                                I2C_BUSY;
                end
                I2C_BUSY:        
                begin
                    /// Strobe when data has been sent.
                    i2cStrobe <= 1'b0;

                    state <= (i2cBusy) ?
                                I2C_BUSY :
                                I2C_DONE;
                end
                INIT_COMPLETE:
                begin
                    i2cStrobe <= 1'b0;
                    state <= INIT_COMPLETE;
                end
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
 
