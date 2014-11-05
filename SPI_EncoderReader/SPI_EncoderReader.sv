/**
 * multi-ServoPWM
 * Joshua Vasquez
 * November 5, 2014
 */

module SPI_EncoderReader( input logic clk,
                          input logic enc0A, enc0B, enc1A, enc1B,
                          input logic cs, sck, mosi, 
                          output logic miso); 

    logic setNewData;
    logic writeEnable;
    logic SPI_DataToSend;

    logic [7:0] dataReceived;
    logic [7:0] addressOut;
    logic [31:0] encoderData[0:1];
 
    QuadratureEncoder encA( .clk(clk), .sigA(enc0A), .sigB(enc0B),
                            .encoderCount(encoderData[0]));

    QuadratureEncoder encB( .clk(clk), .sigA(enc1A), .sigB(enc1B),
                            .encoderCount(encoderData[1]));

    dataCtrl dataCtrlInst(.cs(cs), .sck(sck), .writeEnable(writeEnable),
                          .spiDataIn(dataReceived),
                          .setNewData(setNewData), .addressOut(addressOut));

    spiSendReceive spiInst(.cs(cs), .sck(sck), .mosi(mosi), 
                    .setNewData(setNewData),
                    .dataToSend(SPI_DataToSend), .miso(miso), 
                    .dataReceived(dataReceived));  

    // encoder values are frozen when CS line is pulled low
    mem memInst(.freezeData(~cs), .clk(clk), 
                .encoderDataA(encoderData[0]), .encoderDataB(encoderData[1]),
                .memAddress(addressOut), .memData(SPI_DataToSend));
endmodule



/**
 * \brief data can be written to memory concurrently and read back 
 *        one-byte-at-a-time.
 */
module mem( input logic freezeData, clk,
            input logic [31:0] encoderDataA,
            input logic [31:0] encoderDataB,
            input logic [7:0] memAddress,
           output logic [7:0] memData);

    logic [7:0] mem [0:7];
    
    // freeze changing encoder data on the fetch signal so that it can be 
    // clocked out while it isn't changing
    always_ff @ (posedge clk)
    begin
        mem[0] <= freezeData ? mem[0] : encoderDataA[7:0];
        mem[1] <= freezeData ? mem[1] : encoderDataA[15:8];
        mem[2] <= freezeData ? mem[2] : encoderDataA[23:16];
        mem[3] <= freezeData ? mem[3] : encoderDataA[31:24];
        mem[4] <= freezeData ? mem[4] : encoderDataB[7:0];
        mem[5] <= freezeData ? mem[5] : encoderDataB[15:8];
        mem[6] <= freezeData ? mem[6] : encoderDataB[23:16];
        mem[7] <= freezeData ? mem[7] : encoderDataB[31:24];
    end

    // Implement reading from memory.
    assign memData = mem[memAddress];
 
endmodule
