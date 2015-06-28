module BLDCVelocityController(
        input logic clk, reset,
        input logic [12:0] raw_velocity,
        input logic [12:0] desired_velocity,
        input logic [15:0] encoder_input,
       output logic pwm_phase_a, pwm_phase_b, pwm_phase_c);

iirFilter iir_filter_instance(
            .clk(clk), .reset(reset), .enable('b1),
            .raw_velocity(raw_velocity),
            .filtered_velocity(filtered_velocity));

PIController pi_controller_instance(
                .clk(clk), .desired_velocity(desired_velocity),
                .actual_velocity(filtered_velocity),
                .kp(10), .ki(1),
                .output_gain(output_gain));

fastModulo1170 fast_module_1170_instance(
                    .clk(clk), .reset(reset),
                    .encoder_input(encoder_input),
                    .input_mod_1170(input_mod_1170));

motorCommutation motor_commutation_instance(
                    .clk(clk), .reset(reset), .enable(enable),
                    .gain(output_gain),
                    .cycle_position(input_mod_1170),
                    .pwm_phase_a(pwm_phase_a),
                    .pwm_phase_b(pwm_phase_b),
                    .pwm_phase_c(pwm_phase_c));

endmodule
