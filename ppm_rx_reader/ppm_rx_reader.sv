/**
 * ppm_rx_reader
 * Joshua Vasquez
 * April 28, 2015
 */

module ppm_rx_reader( input logic clk,
                      input logic ppm_signal,
                      output logic [7:0] channnels[0:7]);
/// internal logic:
    logic [2:0] channel;
    logic [7:0] channel_select;
    logic store_time;


/// store_time acts as an enable for the one-hot-encoded channel_select.
    always @ (*)
    begin
        case ({store_time, channel})
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

    always_ff @ (posedge clk)
    begin
        if (reset) begin
            channels[0:7] <= 32'd0;
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
endmodule
