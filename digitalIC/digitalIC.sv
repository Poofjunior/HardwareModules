/**
 * multi-PWM
 * Joshua Vasquez
 * October 16, 2014
 */

module digitalIC( input logic clk,
                  input logic cs, sck, mosi, 
                   output logic miso,
						 output logic [7:0] LEDsOut); 

    logic setNewData;
    logic writeEnable;
	 logic andOut;

    logic [7:0] dataReceived;
	 logic [7:0] addressOut;
	 logic [7:0] dat [0:7];
	 
    dataCtrl dataCtrlInst(.cs(cs), .sck(sck), .writeEnable(writeEnable),
								  .spiDataIn(dataReceived),
                          .setNewData(setNewData), .addressOut(addressOut));
	 

    spiSendReceive spiInst(.cs(cs), .sck(sck), .mosi(mosi), 
                    .setNewData(setNewData),
                    .dataToSend(8'b0), .miso(miso), 
                    .dataReceived(dataReceived));  

    mem memInst(.memAddress(addressOut), .dataToStore(dataReceived),
                        .writeEnable(writeEnable), .fetch(setNewData),
								.pwmDat0(dat[0]),
								.pwmDat1(dat[1]),
								.pwmDat2(dat[2]),
								.pwmDat3(dat[3]),
								.pwmDat4(dat[4]),
								.pwmDat5(dat[5]),
								.pwmDat6(dat[6]),
								.pwmDat7(dat[7]));
								
    pwm pwmInst0(.dutyCycleLookup(dat[0]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[0]));
					 
    pwm pwmInst1(.dutyCycleLookup(dat[1]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[1]));
					 
    pwm pwmInst2(.dutyCycleLookup(dat[2]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[2]));
					 
    pwm pwmInst3(.dutyCycleLookup(dat[3]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[3]));
					 
    pwm pwmInst4(.dutyCycleLookup(dat[4]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[4]));

    pwm pwmInst5(.dutyCycleLookup(dat[5]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[5]));
					 
    pwm pwmInst6(.dutyCycleLookup(dat[6]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[6]));
					 
    pwm pwmInst7(.dutyCycleLookup(dat[7]), 
					 .clk(clk),
					 .pwmOut(LEDsOut[7]));
endmodule








module mem( input logic [7:0] memAddress,
            input logic [7:0] dataToStore,
            input logic writeEnable, fetch,
				output logic [7:0] pwmDat0,
				output logic [7:0] pwmDat1,
				output logic [7:0] pwmDat2,
				output logic [7:0] pwmDat3,
				output logic [7:0] pwmDat4,
				output logic [7:0] pwmDat5,
				output logic [7:0] pwmDat6,
				output logic [7:0] pwmDat7);

    (* ram_init_file = "memData.mif" *) logic [7:0] mem [0:7];

    // Implement writing to memory.
    always_ff @ (posedge fetch)
    begin
        if (writeEnable)
        begin
            mem[memAddress] <= dataToStore;
        end
    end

    // Implement reading from memory.
    //assign memData = mem[memAddress];
	 
	 assign pwmDat0 = mem[0];
	 assign pwmDat1 = mem[1];
	 assign pwmDat2 = mem[2];
	 assign pwmDat3 = mem[3];
	 assign pwmDat4 = mem[4];
	 assign pwmDat5 = mem[5];
	 assign pwmDat6 = mem[6];
	 assign pwmDat7 = mem[7];
endmodule
