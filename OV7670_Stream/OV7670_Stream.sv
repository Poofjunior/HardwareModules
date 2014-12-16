/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014
 */


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
                     output logic dataCtrl);

/// TODO: spoof memory access to circumvent addressing scheme and need for 
///       ram in the middle

logic clk100MHz;
logic newPixel;
logic [15:0] cameraPixelData; 

/// ILI9341 Display needs a faster clock to generate a 50 Meg output speed.
PLL PLL_Inst(.areset(reset), .inclk0(clk), .c0(clk100MHz), .locked());

OV7670_Ctrl OV7670_Inst( .clk(clk), .reset(reset), .vsync(vsync), 
                           .href(href), .pclk(pclk), .OV7670_Data(OV7670_Data),
                           .sda(sda), .scl(scl), .OV7670_Xclk(OV7670_Xclk),
                           .newPixel(newPixel), .pixelData(cameraPixelData));

ILI9341_Driver ILI9341_DriverInst( .CLK_I(clk100MHz), .RST_I(reset), 
                                   .pixelDataIn(cameraPixelData),
                                   .pixelAddr(),
                                   .tftChipSelect(tftChipSelect), 
                                   .tftMosi(tftMosi), .tftSck(tftSck), 
                                   .tftReset(tftReset), .dataCtrl(dataCtrl));
endmodule

