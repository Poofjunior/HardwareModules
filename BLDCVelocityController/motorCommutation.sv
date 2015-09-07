`define HARDWARE_MODULES_DIR(filepath) `"/home/poofjunior/Projects/HardwareModules/filepath`"

module motorCommutation(
            input logic clk, reset, enable,
            input logic [9:0] gain,
            input logic [10:0] cycle_position,
           output logic pwm_phase_a, pwm_phase_b, pwm_phase_c,
           output logic bridge_side_a, bridge_side_b, bridge_side_c);


logic [10:0] lookup_a, lookup_b, lookup_c;

logic signed [11:0] sine_a, sine_b, sine_c;
logic signed [21:0] raw_gain_a, raw_gain_b, raw_gain_c;

logic [21:0] abs_gain_a, abs_gain_b, abs_gain_c;

phaseOffset120 phase_offset_120_instance(
                    .clk(clk), .reset(reset),
                    .cycle_position(cycle_position),
                    .lookup_a(lookup_a),
                    .lookup_b(lookup_b),
                    .lookup_c(lookup_c));

threePhaseSineTable three_phase_sine_table_instance(
                        .clk(clk), .reset(reset),
                        .lookup_a(lookup_a),
                        .lookup_b(lookup_b),
                        .lookup_c(lookup_c),
                        .sine_a(sine_a),
                        .sine_b(sine_b),
                        .sine_c(sine_c));

// TODO: clamp duty_cycle values to max value if they overflow.
// TODO: scale correctly. Taking the upper 10 bits is a complete hack and
//       wont produce the right range.
assign raw_gain_a = (sine_a * gain);
assign raw_gain_b = (sine_b * gain);
assign raw_gain_c = (sine_c * gain);


assign bridge_side_a = (raw_gain_a < 0);
assign bridge_side_b = (raw_gain_b < 0);
assign bridge_side_c = (raw_gain_c < 0);

// Take absolute value. Comparison already done for bridge_side_x logic.
assign abs_gain_a = (bridge_side_a) ?
                            (~raw_gain_a + 1'b1) : // convert to positive
                            raw_gain_a;
assign abs_gain_b = (bridge_side_b) ?
                            (~raw_gain_b + 1'b1) : // convert to positive
                            raw_gain_b;
assign abs_gain_c = (bridge_side_c) ?
                            (~raw_gain_c + 1'b1) : // convert to positive
                            raw_gain_c;


clamp clamp_phase_a(.raw_gain(abs_gain_a),
                    .clipped_gain(clipped_gain_a));
clamp clamp_phase_b(.raw_gain(abs_gain_b),
                    .clipped_gain(clipped_gain_b));
clamp clamp_phase_c(.raw_gain(abs_gain_c),
                    .clipped_gain(clipped_gain_c));


// pwm MUST be 10 bits such that output frequency is 24.44ish [Khz]
pwm pwm_a( .clk(clk), .reset(reset),
           .duty_cycle(clipped_gain_a),
           .pwm(pwm_phase_a));

pwm pwm_b( .clk(clk), .reset(reset),
           .duty_cycle(clipped_gain_b),
           .pwm(pwm_phase_b));

pwm pwm_c( .clk(clk), .reset(reset),
           .duty_cycle(clipped_gain_c),
           .pwm(pwm_phase_c));

endmodule




/**
  \brief takes input electrical position (in encoder ticks) and converts to
         the corresponding signed sine value for that position.
  \details 0-to-2pi is stored in a table. Internal logic serializes
           access to the sine table for all three phases.
*/
module threePhaseSineTable( input logic clk, reset,
                            input logic [10:0] lookup_a,
                            input logic [10:0] lookup_b,
                            input logic [10:0] lookup_c,
                           output logic signed [11:0] sine_a,
                           output logic signed [11:0] sine_b,
                           output logic signed [11:0] sine_c);

(* ram_init_file = `HARDWARE_MODULES_DIR(BLDCVelocityController/velocity_lut.mif) *) logic [11:0] sinewave_a [0:255];
(* ram_init_file = `HARDWARE_MODULES_DIR(BLDCVelocityController/velocity_lut.mif) *) logic [11:0] sinewave_b [0:255];
(* ram_init_file = `HARDWARE_MODULES_DIR(BLDCVelocityController/velocity_lut.mif) *) logic [11:0] sinewave_c [0:255];

/// TODO: implement one sine table with serialized access
///       instead of wasting space
    assign sine_a = sinewave_a[lookup_a];
    assign sine_b = sinewave_b[lookup_b];
    assign sine_c = sinewave_c[lookup_c];
endmodule



/**
 \brief takes input position (in encoder ticks) and maps it to three output
        positions correctly phase offset.
 \details input is a value from 0 through 1170. outputs are three values
          from 0 through 1170, corresponding to 0-to-360 degrees of a sine
          wave.
*/
module phaseOffset120(
            input logic clk, reset,
            input logic [10:0] cycle_position,
           output logic [10:0] lookup_a, lookup_b, lookup_c);

/// bit width should be large enough to identify rollover beyond
/// 0 to 1170 range
logic [10:0] lookup_b_plus_120;
logic signed [11:0] lookup_b_minus_120;

assign lookup_b_plus_120 = cycle_position + 9'd390;
assign lookup_b_minus_120 = cycle_position - 9'd390;

logic overflow_a;
logic underflow_c;

assign overflow_a = (lookup_b_plus_120 > 11'd1120);

assign underflow_c = (lookup_b_minus_120 < 11'd1120);

logic [10:0] lookup_a_mod_1170;
logic [10:0] lookup_c_mod_1170;
assign lookup_a_mod_1170 = lookup_b_plus_120 - 11'd1170;
assign lookup_c_mod_1170 = lookup_b_minus_120 + 11'd1170;

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        lookup_a <= 1'b0;
        lookup_b <= 1'b0;
        lookup_c <= 1'b0;
    end
    else begin
        lookup_a <= overflow_a ? lookup_a_mod_1170[9:0] :
                                 lookup_b_plus_120[9:0];
        lookup_b <= cycle_position;

        lookup_c <= underflow_c ? lookup_c_mod_1170[9:0] :
                                  lookup_b_minus_120[9:0];
    end
end


endmodule



module pwm( input logic clk, reset,
            input logic [10:0] duty_cycle,
           output logic pwm);

logic [10:0] count;

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
        count <= 1'b0;
    else
        begin
            count <= count + 1'b1;
        end
end

assign pwm = (duty_cycle >= count);

endmodule



/// TODO: fix input/output bit widths
module clamp( input logic [31:0] raw_gain,
             output logic [10:0] clipped_gain);

parameter max_val = 11'b11111111111;

    assign clipped_gain = (raw_gain > max_val) ?
                            max_val :
                            raw_gain[10:0];
endmodule
