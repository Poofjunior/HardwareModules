/**
 * synthesizable guts of an peripheral
 * Joshua Vasquez
 * December 5, 2014
 */

/**
 * \brief an spi slave module that both receives input values and clocks out
 *        output values according to SPI Mode0.
 * \details note that the dataToSend input is sampled whenever the setNewData
 *          signal is asserted.
 */
module I2C_Guts(input logic clk, reset,
                input logic [7:0] dataToSend, 
               output logic sda, 
               output logic scl,
               output logic done, 
               output logic deviceAck);    // whether or on device acknowledged

    // These two values seem "off-by one" since affected registers are changing
    // concurrently.
    parameter NINE_BITS_OUT = 8;
    parameter BYTE_OUT = 7;

    logic [3:0] bitCount;
    logic byteTransferred;

    assign scl = (reset) ?  
                    'b0:
                     clk;

    /// bitCount anatomy:
    always_ff @ (negedge clk, posedge reset)
    begin
        if (reset)
        begin
            bitCount <= 'b0;
        end
        else begin
            bitCount <= bitCount + 'b1;
        end
    end


    /// byteTransferred and done register anatomy:
    always_ff @ (negedge clk)
    begin
        if (reset)
        begin
            byteTransferred <= 'b0;
            done <= 'b0;
        end
        else begin
            byteTransferred <= (bitCount == BYTE_OUT)?
                                    'b1 :
                                    byteTransferred;
            done <= (bitCount == NINE_BITS_OUT)?
                        'b1 :
                        done;
        end
    end


    logic [7:0] shiftReg;
    /// shiftReg anatomy:
    always_ff @ (negedge clk, posedge reset)
    begin
        if (reset)
        begin
            shiftReg[7] <= dataToSend[0];
            shiftReg[6] <= dataToSend[1];
            shiftReg[5] <= dataToSend[2];
            shiftReg[4] <= dataToSend[3];
            shiftReg[3] <= dataToSend[4];
            shiftReg[2] <= dataToSend[5];
            shiftReg[1] <= dataToSend[6];
            shiftReg[0] <= dataToSend[7];
        end
        else
        begin
        // Handle Output.
            shiftReg[7:0] <= (shiftReg[7:0] >> 1);
        end
    end
    
    assign sda = byteTransferred ? 
                    'bz :   
                    shiftReg[0];

endmodule
