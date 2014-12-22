/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014
 */

`include <filePaths.sv>


/**
 * \brief streams camera data to the screen at 30 FPS
 */
module OV7670_Stream( /// Camera inputs
                      input logic clk, reset, vsync, href, pclk,
                      input logic [7:0] OV7670_Data,
                      /// Camera outputs
                     output logic sda, scl,
                     output logic OV7670_Xclk,
                     /// Screen outputs
                     output logic tftChipSelect, tftMosi, tftSck, tftReset,
                     output logic dataCtrl,
                     output logic debug);
logic buttonReset;
assign buttonReset = ~reset;

logic clk100MHz;
logic newPixel;
logic [15:0] cameraPixelData; 

logic initPixelStrobe;
assign debug = dataReady;


/// ILI9341 Display needs a faster clock to generate a 50 Meg output speed.
PLL PLL_Inst(.areset(buttonReset), .inclk0(clk), .c0(clk100MHz), .locked());

OV7670_Ctrl OV7670_Inst( .clk(clk), .reset(buttonReset), .vsync(vsync), 
                           .href(href), .pclk(pclk), .OV7670_Data(OV7670_Data),
                           .sda(sda), .scl(scl), .OV7670_Xclk(OV7670_Xclk),
                           .newPixel(newPixel), .pixelData(cameraPixelData));

ILI9341_Driver ILI9341_DriverInst( .CLK_I(clk100MHz), .RST_I(buttonReset), 
                                   .initPixelStrobe(initPixelStrobe), 
                                   // only grab data while pixel isn't changing
                                   .dataReady(href & ~pclk & ~vsync),
                                   //.dataReady(dataReady),
                                   .pixelAddr(),
                                   .pixelDataIn(cameraPixelData),
                                   .tftChipSelect(tftChipSelect), 
                                   .tftMosi(tftMosi), .tftSck(tftSck), 
                                   .tftReset(tftReset), .dataCtrl(dataCtrl));

logic dataReady;
logic [9:0] count;
assign dataReady = ~pclk & ~vsync & (href | (count > 0));

always_ff @ (posedge pclk, posedge vsync)
    begin
        if (vsync)
            count <= 10'b0;
    else
    begin
        if ((href) | ((count > 0) & (count < 640)))
            count <= count + 10'b1;
        else
            count <= 10'b0;
    end
end

logic vsyncEdgeCatch0, vsyncEdgeCatch1;
always_ff @ (posedge clk100MHz, posedge buttonReset)
begin
    if (buttonReset)
    begin
        vsyncEdgeCatch0 <= 1'b0;
        vsyncEdgeCatch1 <= 1'b0;
    end
    else begin
        vsyncEdgeCatch0 <= vsyncEdgeCatch1;
        vsyncEdgeCatch1 <= vsync;
    end
end
assign initPixelStrobe = ~vsyncEdgeCatch0 & vsyncEdgeCatch1;

endmodule

