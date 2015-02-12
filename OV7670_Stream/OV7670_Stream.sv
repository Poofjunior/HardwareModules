/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014 - January 5, 2015
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
                     output logic [7:0] tftParallelPort,
                     output logic tftChipSelect, tftWriteEnable, tftReset,
                     output logic tftDataCmd);
                     
logic buttonReset;
assign buttonReset = ~reset;

logic newPixel;
logic [15:0] cameraPixelData; 

logic initPixelStrobe;


OV7670_Ctrl OV7670_Inst( .clk(clk), .reset(buttonReset), .vsync(vsync), 
                           .href(href), .pclk(pclk), .OV7670_Data(OV7670_Data),
                           .sda(sda), .scl(scl), .OV7670_Xclk(OV7670_Xclk),
                           .newPixel(newPixel), .pixelData(cameraPixelData));

ILI9341_8080_I_Driver ILI_DriverInst( .clk(clk), .reset(buttonReset), 
                                   .newFrameStrobe(initPixelStrobe), 
                                   // only grab data while pixel isn't changing
                                   //.dataReady(href & ~pclk & ~vsync),
                                   .dataReady(href & ~vsync),
                                   .cameraDataIn(OV7670_Data),
                                   .pclk(pclk),
                                   .pixelDataIn(),
                                   .pixelAddr(),
                                   .tftParallelPort(tftParallelPort), 
                                   .tftChipSelect(tftChipSelect), 
                                   .tftWriteEnable(tftWriteEnable), 
                                   .tftReset(tftReset), 
                                   .tftDataCmd(tftDataCmd));


logic vsyncEdgeCatch0, vsyncEdgeCatch1;
always_ff @ (posedge clk, posedge buttonReset)
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

