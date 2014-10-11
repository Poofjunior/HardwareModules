/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * October 9, 2014
 */

module digitalIC( input logic cs, sck, mosi, 
                   output logic miso); 

    logic setNewData;
    logic writeEnable;

    logic [7:0] dataOut;
    logic [7:0] memData;

    dataCtrl dataCtrlInst(.cs(cs), .sck(sck), .setNewData(setNewData), 
                          .writeEnable(writeEnable));

    spiSendReceive spiInst(.cs(cs), .sck(sck), .mosi(mosi), 
                    .setNewData(setNewData),
                    .dataToSend(memData), .miso(miso), 
                    .dataReceived(dataOut));  

    mem memInst(.memAddress(dataOut), .dataToStore(memData),
                        .writeEnable(writeEnable), .fetch(setNewData),
                        .memData(memData));
endmodule



module mem( input logic [7:0] memAddress,
            input logic [7:0] dataToStore,
            input logic writeEnable, fetch,
            output logic [7:0] memData);

    logic [7:0] mem [127:0];

    // Implement writing to memory.
    always_ff @ (posedge fetch)
    begin
        if (writeEnable)
        begin
            mem[memAddress] <= dataToStore;
        end
    end


    // Implement reading from memory.
    assign memData = mem[memAddress];

endmodule
