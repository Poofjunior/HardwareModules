/**
 * An open-drain demultiplexer ideal for interfacing with multiple i2c devices 
 *      with the same device address.
 * \author Joshua Vasquez
 * \date November 7, 2014
 */

module demux( input logic dataIn,
              input logic [2:0] select,
             output logic [7:0] dataOut);

    logic [7:0] busSelect;
	 
    assign busSelect[0] = (~select[2]) & (~select[1]) & (~select[0]); // 3'b000
    assign busSelect[1] = (~select[2]) & (~select[1]) & select[0];  // 3'b001
    assign busSelect[2] = (~select[2]) & select[1] & (~select[0]);  // 3'b010
    assign busSelect[3] = (~select[2]) & select[1] & select[0]; 
    assign busSelect[4] = select[2] & (~select[1]) & (~select[0]); 
    assign busSelect[5] = select[2] & (~select[1]) & select[0]; 
    assign busSelect[6] = select[2] & select[1] & (~select[0]); 
    assign busSelect[7] = select[2] & select[1] & select[0]; 

    assign dataOut[0] = busSelect[0] ? dataIn:
                                    1'b1;
    assign dataOut[1] = busSelect[1] ? dataIn:
                                    1'b1;
    assign dataOut[2] = busSelect[2] ? dataIn:
                                    1'b1;
    assign dataOut[3] = busSelect[3] ? dataIn:
                                    1'b1;
    assign dataOut[4] = busSelect[4] ? dataIn:
                                    1'b1;
    assign dataOut[5] = busSelect[5] ? dataIn:
                                    1'b1;
    assign dataOut[6] = busSelect[6] ? dataIn:
                                    1'b1;
    assign dataOut[7] = busSelect[7] ? dataIn:
                                    1'b1;
endmodule



