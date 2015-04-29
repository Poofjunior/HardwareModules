/**
 * micros_timer.sv
 * Joshua Vasquez
 * April 28, 2015
 */

module micros_timer #(TICKS_PER_MICROSECOND = 50)
                    (input logic clk, reset,
                     output logic [31:0] micros);

    logic [5:0] mhzCount;

    logic mhzReset, mhzCountReset;

/// logic for resetting the counter that triggers once per microsecond
    assign mhzCountReset = (mhzCount == TICKS_PER_MICROSECOND);

/// logic for resetting everything
    assign mhzReset = reset | mhzCountReset;

    always_ff @ (posedge clk)
    begin
        if (mhzReset)
        begin
            mhzCount <= 'b0;
        end
        else
        begin
            mhzCount <= mhzCount + 'b1;
        end
    end


    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
        begin
            micros <= 'b0;
        end
        else
        begin
            micros <= mhzCountReset ?
                            micros + 'b1 :
                            micros;
        end
    end
endmodule
