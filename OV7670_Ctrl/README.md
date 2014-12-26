OV7670_Ctrl
========
## Overview
This module is an OV7670 driver designed for easily getting the camera data
out of the OV7670.
This driver changes the default output (640x480) to 320x240. These settings 
may be tweaked by changing the register values set in _cameraMemData.mif_. 

Much of this driver was based on the excellent summary online from Jorge 
Aparicio, titled
[Hacking the OV7670 Camera Module](http://embeddedprogrammer.blogspot.com/2012/07/hacking-ov7670-camera-module-sccb-cheat.html).
That said, there were a couple of important notes that weren't discussed on 
the blog post. I've covered them in a bit more detail below.

### Pinouts
| Pin    | Type   | Description                   | Details                                    |
|--------|--------|-------------------------------|--------------------------------------------|
| VDD    | INPUT  | 2.8 [V] (min) to 3.3[V] (max) | 3.3[V] exceeds ratings, but works fine     |
| GND    | INPUT  | ground                        |                                            |
| SDIOC  | INPUT  | SCCB Clock                    | I2C functional equivalent to SCL           |
| SDIOD  | INPUT  | SCCB Data                     | I2C functional equivalent to SDA           |
| VSYNC  | OUTPUT | vertical synchronization      |                                            |
| HREF   | OUTPUT | horizontal synchronization    |                                            |
| PCLK   | OUTPUT | Pixel Clock                   | data is strobed out with this clock signal |
| XCLK   | INPUT  | OV7670 Clock                  | connect to a 12.5 - 25 [MHz] signal        |
| D[7:0] | OUTPUT | Parallel Data port            |                                            |
| RESET  | INPUT  | Tie to Logical 0              | This pin must not be left floating         |
| PWDN   | INPUT  | Tie to Logical 1              | This pin must not be left floating         |


### HREF Details 
For any resolution setting, you must also change the
**HSTART** and **HSTOP** timings to their corresponding "magic values." (I'm 
calling them "magic" here since their description isn't documented and I can't
seem to figure out exactly how they change the timings.  Overall, though, 
HSTART and HSTOP change the overall width of the HREF signal by changing the 
start and stop locations of the signal. (Why this needs to be configured 
manually, I don't know.) Ideally, you want the HREF signal to be Logic 1
**only** when a row of pixels is being transferred, no longer, no shorter. 

To keep us from guessing, some Linux Driver Verterans have listed these magic 
values out in their driver [written in C](http://www.cs.fsu.edu/~baker/devices/lxr/http/source/linux/drivers/media/video/ov7670.c). Keep in mind, however, that both the HSTART and HSTOP values are split across two registers in the memory of the
OV7670. From the datasheet, these three registers are (somewhat confusingly)
labeled HSTART(0x17), HSTOP(0x18), and HREF(0x32) and their contents are 
as follows:

|Register Name|Register Address| Register Contents                                              |
|-------------|----------------|----------------------------------------------------------------|
|HREF         |0x32            |bits [2:0] contain HSTART[2:0] and bits [5:3] contain HSTOP[5:3]|
|HSTART       |0x17            |bits[7:0] contain HSTART[10:3]                                  |
|HSTOP        |0x18            |bits[7:0] contain HSTOP[10:3]                                   |

### PCLK Details
Data should be captured on the rising edge of thi PCLK signal. This clock 
signal is a derivative of the input XCLK signal fed into the OV7670.

### SCCB Details
SCCB is a "functional equivalent" to Philips' I2C interface, though there may 
be some subtle differences. (I don't think clock-stretching is implemented.)
If you're planning to write your own driver, keep in mind that the default
built-in I2C peripheral for you microcontroller may not work "out-of-the-box"
because it may also be doing additional checks for ACK/NACKs sent from the 
slave and freeze if these aren't present. I suspect this is the case since
numerous people have tried (including Jorge) to get the default I2C peripheral
working with SCCB, but haven't managed to get it to work. If you can disable
some of those aformentioned "checks," you may be able to get your I2C 
peripheral working with the OV7670's SCCB interface.

For this driver, since everything is handled by the FPGA, I wrote a quick state 
machine that emulates an SCCB transfer.



## Citations:
* Jorge Aparicio's [excellent writeup](http://embeddedprogrammer.blogspot.com/2012/07/hacking-ov7670-camera-module-sccb-cheat.html) for a basic overview
* The [OV7670 Datasheet](http://www.voti.nl/docs/OV7670.pdf)
