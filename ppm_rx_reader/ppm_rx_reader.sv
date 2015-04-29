/**
 * ppm_rx_reader
 * Joshua Vasquez
 * April 28, 2015
 */

module ppm_rx_reader( input logic clk, reset,
                      input logic ppm_signal,
                      output logic [31:0] channels[0:7]);
/// internal logic:
    logic [2:0] channel_index;
    logic [7:0] channel_select;
    logic store_time;
    logic [31:0] micros;
    logic [31:0] last_time;
    logic [31:0] diff_time;

/// Microsecond Timer:
    micros_timer micros_timer_inst(.clk(clk), .reset(reset), .micros(micros));

    always_ff @ (posedge clk, posedge reset)
    if (reset)
    begin
        last_time <= 32'd0;
        diff_time <= 32'd0;
    end
    else begin
        diff_time <= last_time - micros;
        last_time <= (store_time) ? micros :
                                    last_time;
    end


/// store_time acts as an enable for the one-hot-encoded channel_select.
    always @ (*)
    begin
        case ({store_time, channel_index})
        4'b1000: channel_select = 8'b00000001;
        4'b1001: channel_select = 8'b00000010;
        4'b1010: channel_select = 8'b00000100;
        4'b1011: channel_select = 8'b00001000;
        4'b1100: channel_select = 8'b00010000;
        4'b1101: channel_select = 8'b00100000;
        4'b1110: channel_select = 8'b01000000;
        4'b1111: channel_select = 8'b10000000;
        default: channel_select = 8'b00000000;
        endcase;
    end

    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset) begin
            channels[0] <= 32'd0;
            channels[1] <= 32'd0;
            channels[2] <= 32'd0;
            channels[3] <= 32'd0;
            channels[4] <= 32'd0;
            channels[5] <= 32'd0;
            channels[6] <= 32'd0;
            channels[7] <= 32'd0;
        end
        else begin
            channels[0] <= (channel_select[0]) ? diff_time :
                                                 channels[0];
            channels[1] <= (channel_select[1]) ? diff_time :
                                                 channels[1];
            channels[2] <= (channel_select[2]) ? diff_time :
                                                 channels[2];
            channels[3] <= (channel_select[3]) ? diff_time :
                                                 channels[3];
        end
    end



/// new_edge logic for generating state-machine transitions.
    logic synchronizer_begin, synchronizer_end;
    logic edge_detect_begin, edge_detect_end;
    logic new_edge, rising_edge;

    always_ff @ (posedge clk)
    begin
        synchronizer_end <= synchronizer_begin;
        synchronizer_begin <= ppm_signal;

        edge_detect_begin <= synchronizer_end;
        edge_detect_end <= edge_detect_begin;
    end

    assign new_edge = edge_detect_begin ^ edge_detect_end;
    assign rising_edge = new_edge & synchronizer_end;


/// State machine for deducing store_time
/// States:
typedef enum logic[2:0] {FIND_LONG_RISING_EDGE, FIND_LONG_FALLING_EDGE,
                         FIND_RISING_EDGE, PULSE_STORE_TIME_SIG,
                         FIND_FALLING_EDGE, INCREMENT_CHANNEL} state_t;

    parameter IDLE_TIME = 32'd4000;
    parameter NUM_CHANNELS = 32'd8;

    state_t state;

/// Next-State Logic:
    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
            state <= FIND_LONG_RISING_EDGE;
        else
        begin
            case (state)
                FIND_LONG_RISING_EDGE:
                    state <= (new_edge & rising_edge) ?
                                FIND_LONG_FALLING_EDGE :
                                FIND_LONG_RISING_EDGE;
                FIND_LONG_FALLING_EDGE:
                    state <= (new_edge & (diff_time < IDLE_TIME)) ?
                                FIND_RISING_EDGE :
                                FIND_LONG_RISING_EDGE;
                FIND_RISING_EDGE:
                    state <= PULSE_STORE_TIME_SIG ;
                PULSE_STORE_TIME_SIG:
                    state <= FIND_FALLING_EDGE;
                FIND_FALLING_EDGE:
                    state <= (new_edge & (channel_index < NUM_CHANNELS)) ?
                                INCREMENT_CHANNEL:
                                FIND_LONG_RISING_EDGE;
                INCREMENT_CHANNEL:
                    state <= FIND_LONG_RISING_EDGE;
                default: state <= FIND_LONG_RISING_EDGE;
            endcase
        end
    end


    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
        channel_index <= 'b0;
        else begin
            channel_index <= (state == INCREMENT_CHANNEL) ?
                                channel_index + 'b1 :
                                (state == FIND_LONG_RISING_EDGE) ?
                                    'b0:
                                    channel_index;
        end
    end


endmodule
