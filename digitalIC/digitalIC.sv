/**
 * synthesizable spi peripheral
 * Joshua Vasquez
 * October 9, 2014
 */

module digitalIC( input logic cs, sck, mosi, 
                   output logic miso,
						 output logic [7:0] LEDsOut); 

    logic setNewData;
    logic writeEnable;
	 logic andOut;

    logic [7:0] dataReceived;
    logic [7:0] memData;
	 logic [7:0] addressOut;
	 
    dataCtrl dataCtrlInst(.cs(cs), .sck(sck), .spiDataIn(dataReceived),
                          .setNewData(setNewData), .addressOut(addressOut));
	 

    spiSendReceive spiInst(.cs(cs), .sck(sck), .mosi(mosi), 
                    .setNewData(setNewData),
                    .dataToSend(memData), .miso(miso), 
                    .dataReceived(dataReceived));  

    mem memInst(.memAddress(addressOut), .dataToStore(dataReceived),
                        .writeEnable(1'b0/*writeEnable*/), .fetch(setNewData),
                        .memData(memData));
endmodule








module mem( input logic [7:0] memAddress,
            input logic [7:0] dataToStore,
            input logic writeEnable, fetch,
            output logic [7:0] memData);

    (* ram_init_file = "memData.mif" *) logic [7:0] mem [0:255];

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
