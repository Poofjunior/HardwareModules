module motorCommutation(
            input logic clk, reset, enable,
            input logic [9:0] gain,
            input logic [12:0] cycle_position,
           output logic pwm_phase_a, pwm_phase_b, pwm_phase_c);

logic [9:0] lookup_a, lookup_b, lookup_c;
logic [9:0] duty_cycle_a, duty_cycle_b, duty_cycle_c;

phaseOffset120 phase_offset_120_instance(
                    .gain(gain),
                    .lookup_a(lookup_a),
                    .lookup_b(lookup_b),
                    .lookup_c(lookup_c));

threePhaseSineTable three_phase_sine_table_instance(
                        .clk(clk), .reset(reset),
                        .lookup_a(lookup_a),
                        .lookup_b(lookup_b),
                        .lookup_c(lookup_c),
                        .sine_a(duty_cycle_a),
                        .sine_b(duty_cycle_b),
                        .sine_c(duty_cycle_c));

pwm pwm_a( .clk(clk), .reset(reset),
           .duty_cycle(duty_cycle_a),
           .pwm(pwm_phase_a));

pwm pwm_b( .clk(clk), .reset(reset),
           .duty_cycle(duty_cycle_b),
           .pwm(pwm_phase_b));

pwm pwm_c( .clk(clk), .reset(reset),
           .duty_cycle(duty_cycle_b),
           .pwm(pwm_phase_c));

endmodule




module threePhaseSineTable( input logic clk, reset,
                            input logic [9:0] lookup_a,
                            input logic [9:0] lookup_b,
                            input logic [9:0] lookup_c,
                           output logic [9:0] sine_a,
                           output logic [9:0] sine_b,
                           output logic [9:0] sine_c);
/// FIXME: write this later!
always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        sine_a <= 'b0;
        sine_b <= 'b0;
        sine_c <= 'b0;
    end
    else begin
        sine_a <= lookup_a;
        sine_b <= lookup_b;
        sine_c <= lookup_c;
    end
end
endmodule



module phaseOffset120(
            input logic clk, reset,
            input logic [9:0] gain,
           output logic [9:0] lookup_a, lookup_b, lookup_c);

/// bit width should be large enough to identify rollover beyond
/// 0 to 1170 range
logic [10:0] lookup_b_plus_120;
logic [10:0] lookup_b_minus_120;

assign lookup_b_plus_120 = gain + 'd390;
assign lookup_b_minus_120 = gain - 'd390;

logic overflow_a;
logic underflow_c;

assign overflow_a = (lookup_b_plus_120 > 1120);
assign underflow_c = (lookup_b_minus_120 > 1120);

assign lookup_a_mod_1170 = lookup_b_plus_120 - 'd1170;
assign lookup_c_mod_1170 = lookup_b_minus_120 + 'd1170;

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        lookup_a <= 'b0;
        lookup_b <= 'b0;
        lookup_c <= 'b0;
    end
    else begin
        lookup_a <= overflow_a ? lookup_a_mod_1170 : lookup_b_plus_120;
        lookup_b <= gain;
        lookup_c <= underflow_c ? lookup_c_mod_1170 : lookup_b_plus_120;
    end
end


endmodule



module pwm( input logic clk, reset,
            input logic [9:0] duty_cycle,
           output logic pwm);

/// FIXME: actually write this later!
assign pwm = duty_cycle[9];

endmodule
