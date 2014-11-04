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
                  output logic [31:0] encoderCount); 

    typedef enum logic [1:0] {S0, S1, S2, S3} stateType;

    stateType prevState, state, nextState;
    
    always_ff @ (posedge clk)
    begin
        //nextState <= stateType'({sigA, sigB});
        //state <= nextState;
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
