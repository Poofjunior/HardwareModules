/**
 * QuadratureEncoder Counter
 * Joshua Vasquez
 * November 3, 2014
 */

/**
 * \note inputs sigA and sigB MUST be synchronized before entering
 *       this module.
 */
module QuadratureEncoder( input logic clk, sigA, sigB,
                  output logic [15:0] encoderCount); 

    // Note that states correspond with the encoder's grey code, NOT binary.
    typedef enum logic [1:0] {S0 = 2'b00, 
                              S1 = 2'b01, 
                              S2 = 2'b11, 
                              S3 = 2'b10} stateType;

    stateType prevState, state, nextState;
    
    always_ff @ (posedge clk)
    begin
        state <= stateType'({sigA, sigB});
        prevState <= state;
    
    case ( {prevState, state} )
        {S0, S1}: encoderCount <= encoderCount + 1;
        {S1, S2}: encoderCount <= encoderCount + 1;
        {S2, S3}: encoderCount <= encoderCount + 1;
        {S3, S0}: encoderCount <= encoderCount + 1;
        {S2, S1}: encoderCount <= encoderCount - 1;
        {S3, S2}: encoderCount <= encoderCount - 1;
        {S0, S3}: encoderCount <= encoderCount - 1;
        {S1, S0}: encoderCount <= encoderCount - 1;
        default:    encoderCount <= encoderCount;
    endcase

    end


endmodule
