/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * September 26 - October 8, 2014
 */

module spiSendReceive( input logic cs, sck, mosi, setNewData,
            input logic [7:0] dataToSend, 
            output logic miso,
            output logic [7:0] dataReceived);

    logic [7:0] shiftReg;
    logic validClk;
	 
    assign validClk = cs ? 0   :
                           sck;
    
    always_ff @ (negedge validClk, posedge setNewData)
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
    
    always_ff @ (posedge validClk)
    begin
        // Handle Input.
            dataReceived[0] <= mosi;
            dataReceived[1] <= dataReceived[0];
            dataReceived[2] <= dataReceived[1];
            dataReceived[3] <= dataReceived[2];
            dataReceived[4] <= dataReceived[3];
            dataReceived[5] <= dataReceived[4];
            dataReceived[6] <= dataReceived[5];
            dataReceived[7] <= dataReceived[6];
      end

    assign miso = shiftReg[0];

endmodule


module dataCtrl(input logic cs, sck,
                output logic setNewData, writeEnable);

    logic [2:0] bitCount;
    
    assign setNewData = ~bitCount[2] & ~bitCount[1] & ~bitCount[0];

    always_ff @ (negedge sck, posedge cs)
    begin
        if (cs)
            bitCount <= 3'b0;
        else
        begin
            bitCount <= bitCount + 3'b1;
        end
    end
endmodule
