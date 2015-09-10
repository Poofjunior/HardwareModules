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
            input logic signed [13:0] kp, ki,
           output logic signed [10:0] output_gain);

logic signed [31:0] result;
logic signed [15:0] error;
assign error = desired_velocity - actual_velocity;

logic signed [31:0] p_gain;
logic signed [31:0] i_gain;

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

/// Produce an 11-bit output. Clamp overflow to max value.
    output_gain <= result >> 21;
end


//assign output_gain = actual_velocity[9:0];

endmodule
