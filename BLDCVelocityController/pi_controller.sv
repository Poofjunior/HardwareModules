/**
 * \brief a PI controller for calculating the output duty cycle gain
 * \details an enable pulse controls how frequently the controller updates
 */
module PIController(
            input logic clk,
            input logic enable,
            input logic [15:0] desired_velocity,
            input logic [15:0] actual_velocity,
            input logic [13:0] kp, ki,
           output logic [9:0] output_gain);

logic [15:0] error;
assign error = desired_velocity - actual_velocity;

logic [31:0] p_gain;
logic [31:0] i_gain;

/// TODO: handle overflow on i_term
logic [15:0] accumulated_error;

logic [31:0] raw_output;
assign raw_output = p_gain + i_gain;

always_ff @ (posedge clk)
begin
if (enable)
    begin
        p_gain <= kp * error;
        i_gain <= ki * accumulated_error;

    /// TODO: fix windup. This overflows really really fast.
        accumulated_error <= accumulated_error + error;

    /// Produce a 10-bit output. Clamp overflow to max value.
        output_gain <= (p_gain + i_gain) >> 22;
    end
end


endmodule
