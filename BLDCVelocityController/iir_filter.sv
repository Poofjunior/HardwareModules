module iirFilter(
        input logic clk, reset, enable,
        input logic [15:0] raw_velocity,
       output logic [15:0] filtered_velocity);

logic [15:0] last_velocity;
logic [15:0] in_out_difference;
logic [15:0] attenuated_difference;
logic [15:0] filtered_output;

assign filtered_output = last_velocity + (attenuated_difference >> 4);

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        last_velocity <= 'b0;
        attenuated_difference <= 'b0;
        filtered_velocity <= 'b0;
    end
    else if (enable)
    begin
        last_velocity <= filtered_output;
        attenuated_difference <= raw_velocity - last_velocity;
        filtered_velocity <= filtered_output;
    end
    else
// No change.
    begin
        last_velocity <= last_velocity;
        attenuated_difference <= attenuated_difference;
        filtered_velocity <= filtered_velocity;
    end
end

endmodule
