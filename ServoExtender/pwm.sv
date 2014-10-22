/**
 * pwm module with LUT values based on 50[MHz] input clock
 * \author Joshua Vasquez
 * \date September 28, 2014
 */

module pwm( input logic [2:0] dutyCycleLookup, 
            input logic clk,
            output logic pwmOut);

    logic pwmClk;
    logic [8:0] resetCount = 9'b111110100;  // 500 pulses between resets.
    logic [8:0] newCount;
    logic [8:0] dutyCycle;
    logic [8:0] pwmCount;
    logic [8:0] pwmCountPlusOne;
    logic cycleOn;
    logic restartCount;

    assign restartCount = (pwmCount == resetCount);

    assign pwmCountPlusOne = pwmCount + 1'b1;
    assign newCount = restartCount ? 9'b0 :
                                     pwmCountPlusOne;

    pwmLookupTable lookupTable(.address(dutyCycleLookup),
                        .dataOut(dutyCycle));

    slowClk mySlowClk( .clk(clk),
                     .slowClk(pwmClk));

    always_ff @ (posedge pwmClk)
    begin
        pwmCount <= newCount; 
    end

    assign cycleOn = (pwmCount <= dutyCycle);
    assign pwmOut = cycleOn ? 1'b1 :
                       1'b0; 
endmodule

module pwmLookupTable( input logic [2:0] address,
                        output logic [8:0] dataOut);

    // A table of 4 values with 9-bit data.
    logic [8:0] mem [7:0];

     /// Fill in this chart and upgrade the sizes for as much resolution
    /// as you need.
    assign mem[0] = 9'b000000000;
    assign mem[1] = 9'b000000010;
    assign mem[2] = 9'b000000100;
    assign mem[3] = 9'b000001000;
    assign mem[4] = 9'b000010000;
    assign mem[5] = 9'b000100000;
    assign mem[6] = 9'b001000000;
    assign mem[7] = 9'b010000000;

    assign dataOut = mem[address];

endmodule


/*
 * for a PWM module of 5[KHz] as the intended base frequency where we have
 * 500 points of resolution, we'll need a 5 * 500 = 2500[Khz] slow clock.
 * To divide a 50 [MHz] input clock into a 2.5 [MHz] clock, we'll need to 
 * divide by 20 to get the number of pulses needed at 50 [MHz] to cover one
 * cycle at 2500 [KHz].  Finally, our counter will actually only count
 * to half that much since half of the time, our clock will be off, and the
 * other half, our clock will be on.
 */
module slowClk( input logic clk, //reset,
                output logic slowClk);

    logic [3:0] onOffPulses = 4'b1010;  // 10 in decimal
    logic [3:0] count;

    always_ff @ (posedge clk)
    begin
        count <= (count == onOffPulses) ?   4'b0000 :
                                            count + 4'b0001;
        slowClk <= (count == 4'b0) ?    ~slowClk:
                                        slowClk;
    end
endmodule

