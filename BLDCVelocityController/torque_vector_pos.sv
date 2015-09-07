/**
 * \brief adds or subtracts 90 electrical degrees to the current rotor
 *        position to generate the vector of maximum torque given the
 *        current position
 * \details output must still be modded by 1170 (aka, 8192/7) to produce
 *          a relevant cycle position.
 */


module torque_vector_pos(
            input logic [12:0] encoder_ticks,
            input logic direction,
           output logic [12:0] torque_vector_pos);

logic [12:0] forward_vector;
logic [12:0] reverse_vector;
assign forward_vector = encoder_ticks + 12'd292;
assign reverse_vector = encoder_ticks - 12'd292;

assign torque_vector_pos = direction ?
                                forward_vector :
                                reverse_vector;

endmodule
