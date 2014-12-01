/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * September 26 - October 8, 2014
 */

/**
 * \brief an spi slave module that both receives input values and clocks out
 *        output values according to SPI Mode0.
 * \details note that the dataToSend input is sampled whenever the setNewData
 *          signal is asserted.
 * \note `mosi' and `miso' signals have been replaced with more
 *        general-purpose terms serialDataIn and serialDataOut to free the 
 *        module from being constrained to master or slave-specific naming
 *        conventions.
 */
module spiSendReceive( input logic sck, serialDataIn, setNewData,
            input logic [7:0] dataToSend, 
            output logic serialDataOut,
            output logic [7:0] dataReceived);

    logic [7:0] shiftReg;
  
    always_ff @ (negedge sck, posedge setNewData)
    begin
        if (setNewData)
        begin
            shiftReg[7] <= dataToSend[0];
            shiftReg[6] <= dataToSend[1];
            shiftReg[5] <= dataToSend[2];
            shiftReg[4] <= dataToSend[3];
            shiftReg[3] <= dataToSend[4];
            shiftReg[2] <= dataToSend[5];
            shiftReg[1] <= dataToSend[6];
            shiftReg[0] <= dataToSend[7];
        end
        else
        begin
        // Handle Output.
            shiftReg[7:0] <= (shiftReg[7:0] >> 1);
        end
    end
    
    always_ff @ (posedge sck)
    begin
        // Handle Input.
            dataReceived[0] <= serialDataIn;
            dataReceived[1] <= dataReceived[0];
            dataReceived[2] <= dataReceived[1];
            dataReceived[3] <= dataReceived[2];
            dataReceived[4] <= dataReceived[3];
            dataReceived[5] <= dataReceived[4];
            dataReceived[6] <= dataReceived[5];
            dataReceived[7] <= dataReceived[6];
      end

    assign serialDataOut = shiftReg[0];

endmodule



/**
 * \brief handles when data should be loaded into the spi module 
 */
module dataCtrl(input logic cs, sck, 
                output logic setNewData);

    logic [10:0] bitCount;
    logic byteOut;
    logic byteOutNegEdge;
    logic andOut;	// somewhat unecessary intermediate wire name.
    assign andOut = bitCount[2] & bitCount[1] & bitCount[0];

/// byteOut logic:   
      always_ff @ (posedge sck, posedge cs)
    begin
        if (cs)
        begin
            bitCount <= 5'b0000;
            byteOut <= 1'b1;
        end
    else
        begin
            bitCount <= bitCount + 5'b0001;
            byteOut <= andOut;
        end
    end

/// byteOutNegEdge and setNewData logic: 
    always_ff @ (negedge sck, posedge cs)
    begin
        if (cs)
            byteOutNegEdge <= 1'b1;
        else
            byteOutNegEdge <= byteOut;
        end


//        assign setNewData = byteOutNegEdge & ~sck;
    always_latch
    begin
        if (byteOutNegEdge)
        begin
            setNewData <= byteOut;
        end
    end

endmodule
