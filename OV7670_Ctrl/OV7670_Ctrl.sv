/**
 * OV7670_Ctrl
 * Joshua Vasquez
 * December 5, 2014
 */
`include <filePaths.sv>

`define MEM_DEPTH 123


/**
 * \brief initializes the OV7670 with the desired I2C settings and extracts
 *        each pixel
 */
module OV7670_Ctrl( input logic clk, reset, pclk,
                    input logic [7:0] OV7670_data_in,
                   output logic sda, scl,
                   output logic OV7670_Xclk,
                   output logic [7:0] OV7670_data_out);

    logic i2cClk, i2cStrobe;
    logic [7:0] memAddr;
    logic [8:0] memData;
    logic busy, lastTransfer;
    logic [7:0] dataToSend;

    assign OV7670_data_out[7:0] = OV7670_data_in[7:0];


    OV7670_Driver OV7670_DriverInst( .clk(clk), .reset(reset),
                                     .pclk(pclk),
                                     .i2cBusy(busy),
                                     .memData(memData),
                                     .dataToSend(dataToSend),
                                     .i2cStrobe(i2cStrobe),
                                     .lastTransfer(lastTransfer),
                                     .memAddr(memAddr),
                                     .OV7670_Xclk(OV7670_Xclk));

    I2C_Guts I2C_GutsInst(.clk(clk), .reset(reset),
                          .i2cStrobe(i2cStrobe),
                          .dataToSend(dataToSend),
                          .lastTransfer(lastTransfer),
                          .sda(sda), .scl(scl),
                          .busy(busy));

    initCameraParams initCameraParamsInst(.memAddress(memAddr),
                                          .memData(memData));


endmodule


/**
 * \brief the main logic block containing the finite-state machine to interact
 *        with the camera.
 */
module OV7670_Driver(input logic clk, reset, pclk,
                     input logic i2cBusy,
                     input logic [8:0] memData,
                    output logic [7:0] dataToSend,  // over SCCB interface
                    output logic i2cStrobe, lastTransfer,
                    output logic [7:0] memAddr,
                    output logic OV7670_Xclk);

    parameter LAST_INIT_PARAM_ADDR = `MEM_DEPTH;
    parameter SETTINGS_MEM_SIZE = `MEM_DEPTH;

    /// Note: these constants are based on a 50[MHz] clock speed.
    parameter RESET_TIME = 6000000; // 120 MS in clock ticks at 50 MHz
    parameter DELAY_ONE = 10;

    /// 8'b1 puts output at 15FPS
    /// 8'b0 puts output at 30FPS
    OV7670_ClkDiv OV7670_ClkInst(clk, reset, 8'b0, OV7670_Xclk);

    //logic frameGrabberReset;


/*
    frameGrabber frameGrabberInst(.pclk(pclk),
                                  .reset(frameGrabberReset),
                                  .cameraData(OV7670_Data),
                                  .pixel(pixelData),
                                  .rows(),
                                  .cols(),
                                  .newData(newPixel));
*/

    logic [24:0] delayTicks;
    logic delayOff;
    assign delayOff = &(~delayTicks);


    typedef enum logic [2:0] {INIT, I2C_DONE, I2C_BUSY, INIT_COMPLETE,
                              NEW_FRAME}
                              stateType;

    stateType state;

    always_ff @ (posedge clk, posedge reset)
    begin
        if (reset)
        begin
            state <= INIT;
            delayTicks <= 'b0;
            memAddr <= 'b0;
            lastTransfer <= memData[8];
            i2cStrobe <= 'b0;
            delayTicks <= 'b0;
            //frameGrabberReset <= 1'b1;
        end
        else if (delayOff)
        begin
            case (state)
                INIT:
                begin
                    delayTicks <= RESET_TIME;
                    state <= I2C_DONE;
                    dataToSend <= memData[7:0]; /// load first byte only
                end
                I2C_DONE:
                begin
                    delayTicks <= DELAY_ONE;
                    i2cStrobe <= (memAddr == LAST_INIT_PARAM_ADDR)?
                                    1'b0 :
                                    1'b1;

                    memAddr <= memAddr + 'b1;
                    lastTransfer <= memData[8];
                    dataToSend <= memData[7:0];
                    state <= (memAddr == LAST_INIT_PARAM_ADDR) ?
                                INIT_COMPLETE:
                                I2C_BUSY;
                end
                I2C_BUSY:
                begin
                    /// Strobe when data has been sent.
                    i2cStrobe <= 1'b0;

                    state <= (i2cBusy) ?
                                I2C_BUSY :
                                I2C_DONE;
                end
                INIT_COMPLETE:
                begin
                    i2cStrobe <= 1'b0;
                    state <= INIT_COMPLETE;
                    //frameGrabberReset <= (vsync & ~href);
                end
            endcase
        end
        else
            delayTicks <= delayTicks - 'b1;
    end
endmodule


module frameGrabber( input logic pclk, reset,
                     input logic [7:0] cameraData,
                     output logic [15:0] pixel,
                     output logic [7:0] rows,
                     output logic [8:0] cols,
                     output logic newData);
    logic MSB;

    always_ff @ (posedge pclk, posedge reset)
    begin
        if (reset)
        begin
            rows <= 7'b0;
            cols <= 8'b0;
            MSB <= 1'b1;
            newData <= 1'b0;
            pixel[15:0] <= 16'b0;
        end
        else begin
            MSB <= ~MSB;
            // TODO: remove magic numbers
            rows <= MSB ?
                        (rows == 240) ?
                            7'b0:
                            rows + 7'b1 :
                        rows;
            cols <= (MSB & (rows == 240))?
                        (cols == 320) ?
                            8'b0:
                            cols + 8'b1  :
                        cols;

            if (MSB)
            begin
                pixel[15:8] <= cameraData;
                newData <= 1'b0;
            end
            else
            begin
                pixel[7:0] <= cameraData;
                newData <= 1'b1;
            end
        end
    end
endmodule


/**
 * \brief contains settings to send to camera
 * \details MSbit indicates end of a single transfer
 */
module initCameraParams(  input logic [7:0] memAddress,
                         output logic [8:0] memData);
    // TODO: Make global and declarable in the top level module.

    (* ram_init_file = `HARDWARE_MODULES_DIR(OV7670_Ctrl/cameraMemData.mif) *) logic [8:0] mem [0:`MEM_DEPTH - 1];

    assign memData = mem[memAddress];

endmodule


module OV7670_ClkDiv( input logic clk, reset,
               input logic [7:0] divInput,      // clock divisor
              output logic slowClk);

    logic [7:0] divisor;    /// divisor (aka: divInput) should never be 0.
    logic countMatch;
    logic [7:0] count;

    assign countMatch = (divisor == count);

    always_ff @ (posedge clk)
    begin
        divisor <= divInput;
    end

    always_ff @ (posedge clk)
    begin
        if (reset | countMatch )  // count reset must be synchronous.
            count <= 8'b00000000;
        else
            count <= count + 8'b00000001;
    end

    always_ff @ (posedge clk, posedge reset)
    if (reset)
            slowClk <= 'b0;
    else
    begin
            slowClk <= (countMatch) ?
                            ~slowClk :
                            slowClk;
    end
endmodule

