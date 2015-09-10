/**
 * Quadrature Encoder Counter
 * Joshua Vasquez
 * November 3, 2014
 */

/**
 * \note inputs sig_a and sig_b MUST be synchronized before entering
 *       this module.
 */
module QuadratureEncoder( input logic clk, reset, sig_a, sig_b,
                         output logic [31:0] encoder_count,
                         output logic state_change,
                         output logic direction);

// Note that states correspond with the encoder's grey code, NOT binary.
typedef enum logic [1:0] {S0 = 2'b00,
                          S1 = 2'b01,
                          S2 = 2'b11,
                          S3 = 2'b10} stateType;

stateType prevState, state, nextState;

always_ff @ (posedge clk, posedge reset)
if (reset)
begin
    encoder_count <= 'b0;
end
else begin
    state <= stateType'({sig_a, sig_b});
    prevState <= state;

case ( {prevState, state} )
    {S0, S1}:
    begin
        encoder_count <= encoder_count + 1;
        direction <= 1'b1;
    end
    {S1, S2}:
    begin
        encoder_count <= encoder_count + 1;
        direction <= 1'b1;
    end
    {S2, S3}:
    begin
        encoder_count <= encoder_count + 1;
        direction <= 1'b1;
    end
    {S3, S0}:
    begin
        encoder_count <= encoder_count + 1;
        direction <= 1'b1;
    end
    {S2, S1}:
    begin
        encoder_count <= encoder_count - 1;
        direction <= 1'b0;
    end
    {S3, S2}:
    begin
        encoder_count <= encoder_count - 1;
        direction <= 1'b0;
    end
    {S0, S3}:
    begin
        encoder_count <= encoder_count - 1;
        direction <= 1'b0;
    end
    {S1, S0}:
    begin
        encoder_count <= encoder_count - 1;
        direction <= 1'b0;
    end
    default:
    begin
        encoder_count <= encoder_count;
        direction <= 1'b1;
    end
endcase

end

assign state_change = (prevState != state);

endmodule
