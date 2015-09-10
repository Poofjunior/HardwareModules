module motor_control_unit(
            input logic clk, reset,
           output logic reset_encoder_count,
           output logic apply_initial_commutation,
           output logic controller_override,
           output logic control_loop_pulse,
           output logic filter_pulse,
           output logic commutation_enable);


typedef enum logic [1:0] { INIT,
                           VECTOR_ALIGN_DELAY,
                           ZERO_ENCODER_DELAY,
                           STANDARD_OPERATION} stateType;

stateType state;

logic delay_off;
logic [31:0] delay_time;

parameter VECTOR_ALIGN_DELAY_TICKS = 'd100000000;
parameter ZERO_ENCODER_DELAY_TICKS = 'd5000000;

assign delay_off = ~(&delay_time);

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        state <= INIT;
    end
    else if (delay_off)
    begin
        case (state)
            INIT:
            begin
                state <= VECTOR_ALIGN_DELAY;
                delay_time <= VECTOR_ALIGN_DELAY_TICKS;
            end
            VECTOR_ALIGN_DELAY:
            begin
                state <= ZERO_ENCODER_DELAY;
                delay_time <= ZERO_ENCODER_DELAY_TICKS;
            end
            ZERO_ENCODER_DELAY:
                state <= STANDARD_OPERATION;
            STANDARD_OPERATION:
                state <= STANDARD_OPERATION;
            default: state <= STANDARD_OPERATION;
        endcase
    end
    else delay_time <= delay_time - 'b1;
end


always_ff @ (posedge clk)
begin
    commutation_enable <= (state == VECTOR_ALIGN_DELAY) ||
                          (state == STANDARD_OPERATION);
end


always_ff @ (posedge clk)
begin
    case (state)
        VECTOR_ALIGN_DELAY:
        begin
            apply_initial_commutation <= 'b1;
            controller_override <= 'b1;
        end
        default
        begin
            apply_initial_commutation <= 'b0;
            controller_override <= 'b0;
        end
    endcase
end


always_ff @ (posedge clk)
begin
    case (state)
        ZERO_ENCODER_DELAY: reset_encoder_count <= 'b1;
        default reset_encoder_count <= 'b0;
    endcase
end

motorEnablePulseGen( .clk(clk), .reset(reset),
                     .update_loop(control_loop_pulse));

/// Quick hack.. for now.
assign filter_pulse = control_loop_pulse;

endmodule



module motorEnablePulseGen( input logic clk, reset,
                          output logic update_loop);

/// count counts up to 50,000
logic [15:0] count;
parameter count_threshold = 16'd50000;

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        update_loop <= 1'b0;
        count <= 16'b0;
    end
    else begin
        count <= (count == count_threshold) ?
                    16'b0 :
                    count + 16'b1;

        update_loop <= (count == 16'b0);
    end
end

endmodule
