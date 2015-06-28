module PIController(
            input logic clk,
            input logic [15:0] desired_velocity,
            input logic [15:0] actual_velocity,
            input logic [15:0] kp, ki,
           output logic [9:0] output_gain);

logic [15:0] error;
assign error = desired_velocity - actual_velocity;

logic [31:0] p_gain;
logic [31:0] i_gain;

/// TODO: handle overflow on i_term
logic [15:0] accumulated_error;

always_ff @ (posedge clk)
begin
    p_gain <= kp * error;
    i_gain <= ki * accumulated_error;

/// TODO: fix windup. This overflows really really fast.
    accumulated_error <= accumulated_error + error;

/// Produce a 10-bit output.
    output_gain <= (p_gain + i_gain) >> 22;
end


endmodule
