module BLDCVelocityController(
        input logic clk, reset,
        input logic enable, // TODO: reroute enable to the internal controller.
        input logic signed [15:0] desired_velocity,
        input logic encoder_a, encoder_b,
       output logic pwm_phase_a, pwm_phase_b, pwm_phase_c);

logic encoder_change;
logic encoder_direction; // unused

logic controller_override;
logic control_loop_pulse;
logic filter_pulse;
logic commutation_enable;

logic [10:0] input_mod_1170;

logic signed [11:0] output_gain;
logic signed [11:0] output_gain_mux_out;
logic signed [15:0] filtered_velocity;

logic [31:0] encoder_count;
logic [31:0] time_per_tick;
logic [12:0] torque_vector_pos;
logic [15:0] raw_velocity;
logic [15:0] raw_velocity_mux_out;

logic reset_encoder_count;
logic apply_initial_commutation;

/// TODO: add synchronizer to asynchronous encoder inputs.
QuadratureEncoder encoder_instance(.clk(clk), .reset(reset),
                                   .sig_a(encoder_a), .sig_b(encoder_b),
                                   .encoder_count(encoder_count),
                                   .state_change(encoder_change),
                                   .direction(encoder_direction));


TickTimer tick_timer_instance( .clk(clk), .reset(reset),
                                .state_change(encoder_change),
                                .time_per_tick(time_per_tick));


motor_control_unit control_unit_instance(
                        .clk(clk),
                        .reset(reset),
                        .reset_encoder_count(reset_encoder_count),
                        .apply_initial_commutation(apply_initial_commutation),
                        .controller_override(controller_override),
                        .control_loop_pulse(control_loop_pulse),
                        .filter_pulse(filter_pulse),
                        .commutation_enable(commutation_enable));


TickTimeToVelocityLookup velocity_lut(.time_per_tick(time_per_tick[13:0]),
                                      .velocity(raw_velocity));


assign raw_velocity_mux_out = (time_per_tick > 16'h07FF) ?
                                    16'b0 :
                                     raw_velocity;


iirFilter iir_filter_instance(
            .clk(clk), .reset(reset), .enable(filter_pulse),
            .raw_velocity(raw_velocity_mux_out),
            .filtered_velocity(filtered_velocity));


PIController pi_controller_instance(
                .clk(clk),
                .reset(reset),
                .enable(control_loop_pulse),
                .desired_velocity(desired_velocity),
                .actual_velocity(filtered_velocity),
                .kp(10), .ki(0),
                .output_gain(output_gain));


///FIXME: output is wrong in the RTL.  Wat.
/*
assign output_gain_mux_out = (controller_override) ?
                                1'b1:
                                output_gain;
*/
parameter [11:0] fixed_gain = 12'h7FF;
always_comb
begin
    integer i;
    for (i = 0; i < 12; i = i + 1)
    begin
        output_gain_mux_out[i] = (controller_override) ?
                                    fixed_gain[i] :
                                    output_gain[i];
    end
end


//assign output_gain_mux_out = output_gain;

torque_vector_pos advance_angle_generator( .encoder_ticks(encoder_count[12:0]),
                                           .direction(desired_velocity[15]),
                                           .torque_vector_pos(torque_vector_pos));


fastModulo1170 fast_module_1170_instance(
                    .clk(clk), .reset(reset),
                    .encoder_input(torque_vector_pos),
                    .input_mod_1170(input_mod_1170));


motorCommutation motor_commutation_instance(
                    .clk(clk), .reset(reset), .enable(commutation_enable),
                    .gain(output_gain_mux_out),
                    .cycle_position(input_mod_1170),
                    .pwm_phase_a(pwm_phase_a),
                    .pwm_phase_b(pwm_phase_b),
                    .pwm_phase_c(pwm_phase_c));
endmodule
