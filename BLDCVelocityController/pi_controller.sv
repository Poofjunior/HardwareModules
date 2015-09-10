/**
 * \brief a PI controller for calculating the output duty cycle gain
 * \details an enable pulse controls how frequently the controller updates
 */
module PIController(
            input logic clk,
            input logic reset,
            input logic enable,
            input logic signed [15:0] desired_velocity,
            input logic signed [15:0] actual_velocity,
            input logic signed [15:0] kp, ki,
           output logic signed [11:0] output_gain);

/// 33 bits to detect overflow.
logic signed [32:0] result;
logic signed [15:0] error;
assign error = desired_velocity - actual_velocity;

logic signed [32:0] p_gain;
logic signed [32:0] i_gain;

/// TODO: handle overflow on i_term
logic signed [15:0] accumulated_error;

assign result = (p_gain + i_gain);

always_ff @ (posedge clk, posedge reset)
if (reset)
begin
    p_gain <= 'b0;
    i_gain <= 'b0;
    accumulated_error = 'b0;
    output_gain <= 'b0;
end
else if (enable)
begin
    p_gain <= kp * error;
    i_gain <= ki * accumulated_error;

/// TODO: fix windup. This overflows pretty quickly.
    accumulated_error <= accumulated_error + error;

/// FIXME: verify that this clamping makes sense.
/// TODO: clamp output to prevent overflow!
/// Produce a 12-bit output. Clamp overflow to max value.
/// Clamp overflow too, but it's already 0.
    output_gain <= result[32] ?
                    12'h7FF:
                    result[31:20];
end


//assign output_gain = actual_velocity[9:0];

endmodule
