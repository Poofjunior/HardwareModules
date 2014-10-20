/**
 * servo pwm module with 8-bit duty cycle input based on 50[MHz] input clock
 * \author Joshua Vasquez
 * \date October 19, 2014
 */

module ServoPWM( input logic [7:0] dutyCycle, 
                 input logic clk,
                output logic pwmOut);

    logic [7:0]  onPulseBiasCount;
    logic [8:0]  onTime;
    logic [11:0] count;
    logic countReset;
    logic slowClk;
	 
    clkDiv256 clkDiv256_Inst(.clk(clk), .slowClk(slowClk));

    assign onPulseBiasCount = 7'd64;    // 0.5 [ms] in clkDiv256 pulses

    assign countReset = (count >= 12'd2560);  // 20 [ms] in clkDiv256 pulses

    always_ff @ (posedge slowClk, posedge countReset)
    begin
        if (countReset)
        begin
            count <= 12'b0;
        end
        else begin
            count <= count + 12'b1;
        end
    end
	 
    
    always_ff @ (posedge slowClk)
	 begin
        onTime <= onPulseBiasCount+ dutyCycle;
        pwmOut <= (count <= onTime);
	 end
    
endmodule



/*
 * \brief divides the input 50 [Mhz] clock signal by 256.
 * \details within a 2[ms] period, 100,000 clock pulses at 50[Mhz] occur. To
 *          divide by 256, we will count 390.625 pulses at 50[Mhz] for every
 *          slowClk pulse. Since we want the clock to turn on and off to count
 *          a pulse, we will actually count to 195.3125 each time we toggle
 *          the slowClk output.
 */
module clkDiv256( input logic clk,
                 output logic slowClk);

    logic [7:0] onOffPulses = 8'd195;   // 195.3125 integer approximation.
    logic [7:0] count;

    always_ff @ (posedge clk)
    begin
        count <= (count == onOffPulses) ?   8'b0:
                                            count + 8'b1;
        slowClk <= (count == 8'b0) ?    ~slowClk:
                                        slowClk;
    end
endmodule

