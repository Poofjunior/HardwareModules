/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * September 26 - 27, 2014
 */

module spi( input logic cs, sck, mosi, 
            output logic miso, 
            output logic [7:0] LEDsOut);

            logic [7:0] temp;
            assign temp[7:0] = LEDsOut;

    spiSendReceive spiInst(.cs(cs), .sck(sck), .mosi(mosi),
                    .dataToSend(temp), .miso(miso), // Test: send 7
                    .dataReceived(LEDsOut));               // display data 
endmodule


module spiSendReceive( input logic cs, sck, mosi,
            input logic [7:0] dataToSend, 
            output logic miso,
            output logic [7:0] dataReceived);

    logic [7:0] shiftReg;
    
    assign validClk = cs ? 0   :
                           sck;

    
    always_ff @ (negedge validClk, posedge cs)
    begin
        if (cs)
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
    
    always_ff @ (posedge validClk, negedge cs)
    begin
        if (~cs)
        begin
            dataReceived[7:0] <= 8'b0;
        end
        else
        begin
        // Handle Input.
            dataReceived[7] <= mosi;
            dataReceived[6] <= dataReceived[7];
            dataReceived[5] <= dataReceived[6];
            dataReceived[4] <= dataReceived[5];
            dataReceived[3] <= dataReceived[4];
            dataReceived[2] <= dataReceived[3];
            dataReceived[1] <= dataReceived[2];
            dataReceived[0] <= dataReceived[1];
        end
    end

    assign miso = shiftReg[0];

endmodule
