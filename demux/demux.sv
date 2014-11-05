/**
 * An open-drain demultiplexer ideal for interfacing with multiple i2c devices 
 *      with the same device address.
 * \author Joshua Vasquez
 * \date October 19, 2014
 */

module demux( input logic dataIn
                 input logic [3:0] select,
                output logic [7:0] dataOut);

    logic [7:0] busSelect;
    case (sel)
        4'b0000: busSelect = 8'b00000000; 
        4'b0001: busSelect = 8'b00000001; 
        4'b0010: busSelect = 8'b00000010; 
        4'b0011: busSelect = 8'b00000100; 
        4'b0100: busSelect = 8'b00001000; 
        4'b0101: busSelect = 8'b00010000; 
        4'b0110: busSelect = 8'b00100000; 
        4'b0111: busSelect = 8'b01000000; 
        4'b1000: busSelect = 8'b10000000; 
    endcase

    for (...)
    assign dataOut[i] = busOut[i] ? dataIn:
                                    1'bz;
endmodule



