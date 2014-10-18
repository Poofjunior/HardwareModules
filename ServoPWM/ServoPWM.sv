/**
 * pwm module with 8-bit duty cycle input based on 50[MHz] input clock
 * \author Joshua Vasquez
 * \date September 28, 2014
 */

module ServoPWM( input logic [7:0] dutyCycle, 
                 input logic clk,
                output logic pwmOut);

    logic [7:0]  onPulseBiasCount;
    logic [7:0]  onTime;
    logic [16:0] count;

    assign onPulseBiasCount = 7'd98;    // 0.5 [ms] in clkDiv256 pulses

    assign countReset = (count >= 17'd100000);  // 20 [ms] im clkDiv256 pulses

    always_ff @ (posedge clk, posedge countReset)
    begin
        if (countReset)
        begin
            count <= 0;
        end
        else begin
            onTime <= onPulseBiasCount + dutyCycle;
            count <= count + 1'b1;
        end
    end

    assign pwmOut = (onTime <= count[7:0]);
    
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

    logic [7:0] onOffPulses = 9'd195;   // 195.3125 integer approximation.
    logic [7:0] count;

    always_ff @ (posedge clk)
    begin
        count <= (count == onOffPulses) ?   8'b0:
                                            count + 8'b00000001;
        slowClk <= (count == 8'b0) ?    ~slowClk:
                                        slowClk;
    end
endmodule

