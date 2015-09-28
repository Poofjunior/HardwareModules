/**
 * FIFO buffer
 * Joshua Vasquez
 * September 15, 2015
 */

/**
 * \brief a fifo buffer
 * \details DATA_ENTRIES must be a power of 2 (i.e: 128, 256, etc.)
 * \param write_enable one clock cycle per write
 * \param read_enable one clock cycle per read
 * \param 
 */
module fifo
#(parameter DATA_WIDTH = 8,
  parameter DATA_ENTRIES = 256)
    ( input logic clk, reset,
      input logic [DATA_WIDTH-1:0] data_input,
      input logic write_enable,
      input logic read_enable, // data removed on falling edge.
     output logic [DATA_WIDTH-1:0] data_output,
     output logic [$clog2(DATA_ENTRIES):0] num_entries,
     output logic fifo_full,
     output logic fifo_empty);

logic [DATA_WIDTH-1:0] async_mem [0:DATA_ENTRIES-1];

logic [$clog2(DATA_ENTRIES)-1:0] write_address;
logic [$clog2(DATA_ENTRIES)-1:0] read_address;

logic write_increment;
logic read_increment;

logic [1:0] write_nedge_catch;
logic [1:0] read_nedge_catch;


/// num_entries logic for tracking the number of entries in the fifo
always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        num_entries <= 'b0;
    end
    else begin
        casez ({write_enable, read_enable})
            2'b01: num_entries <= (num_entries == 'b0 )?
                                    num_entries:
                                    num_entries - 'b1;
            2'b10: num_entries <= (num_entries == DATA_ENTRIES)?
                                    num_entries:
                                    num_entries + 'b1;
         default: num_entries <= num_entries;
        endcase
    end
end


assign data_output = async_mem[read_address];
always_ff @ (posedge clk)
begin
    if (write_enable)
        async_mem[write_address] <= data_input;
end

assign fifo_empty = (num_entries == 'b0);
assign fifo_full = (num_entries == DATA_ENTRIES);

assign write_increment = write_enable;
assign read_increment = (read_enable | (fifo_full & write_increment))
                        & ~fifo_empty;


address_generator #(.DATA_ENTRIES(DATA_ENTRIES))
    write_address_gen( .clk(clk),
                       .reset(reset),
                       .increment(write_increment),
                       .address(write_address));

address_generator #(.DATA_ENTRIES(DATA_ENTRIES))
    read_address_gen( .clk(clk),
                       .reset(reset),
                       .increment(read_increment),
                       .address(read_address));
endmodule



module address_generator
#(parameter DATA_ENTRIES = 256)
    ( input logic clk, reset,
      input logic increment,
     output logic [$clog2(DATA_ENTRIES)-1:0] address);

always_ff @ (posedge clk, posedge reset)
begin
    if (reset)
    begin
        address <= 'b0;
    end
    else begin
        address <= increment ?
                    address + 'b1 :
                    address;
    end
end

endmodule
