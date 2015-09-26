/**
 * buffered spi
 * Joshua Vasquez
 */

/**
 * \brief an spi slave
 * \details DATA_WIDTH defines the number of bits per SPI transfer and
 *          must be a multiple of 8.
 */
module spi
#(parameter DATA_WIDTH = 8)
          ( input logic clk, reset,
            input logic cs, sck, mosi,
            input logic read_data,
           output logic miso,
           output logic busy,
            input logic [(DATA_WIDTH-1):0] data_to_send,
           output logic [(DATA_WIDTH-1):0] data_received,
           output logic [(DATA_WIDTH-1):0] LEDsOut );

logic clear_new_data;
logic [1:0] new_data_edge;
logic write_enable;

logic not_reset;
assign not_reset = ~reset;

logic [DATA_WIDTH-1:0] spi_data_received;


/// Clear new data as soon as it arrives to prevent it from being
/// continuously loaded into the buffer.
always_ff @ (posedge clk, posedge not_reset)
begin
    if (not_reset)
    begin
        clear_new_data <= 'b0;
        new_data_edge[1:0] <= 'b0;
    end
    else begin
        clear_new_data <= new_data;
        new_data_edge[0] <= new_data_edge[1];
        new_data_edge[1] <= new_data;
    end
end

assign write_enable = new_data_edge[1] & ~new_data_edge[0];

spi_slave_interface #(DATA_WIDTH)
    spi_inst(.clk(clk),
             .reset(not_reset),
             .cs(cs),
             .sck(sck),
             .mosi(mosi),
             .miso(miso),
             .clear_new_data_flag(clear_new_data),
             .busy(busy),
             .synced_new_data_flag(new_data),
             .data_to_send(data_to_send),
             .synced_data_received(spi_data_received));


assign LEDsOut = spi_data_received;


fifo #(.DATA_WIDTH(DATA_WIDTH),
       .DATA_ENTRIES(256))
     fifo_inst(.clk(clk),
               .reset(not_reset),
               .data_input(spi_data_received),
               .write_enable(write_enable),
               .read_enable(read_data),
               .data_output(data_received),
               //.num_entries(LEDsOut),
               .num_entries(),
               .fifo_full(),
               .fifo_empty());
endmodule

