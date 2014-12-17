OV7670_Ctrl
========
## Overview
This module is an OV7670 driver designed for easily getting the camera data
out of the OV7670.


## Notes
If you're planning to write your own driver (be it Arduino, Verilog, etc.), 
here's a couple of notes that I found along the way.
* You supply the OV7670 with an input clock frequency on XCLK
* Read the 8-bit data on the rising PCLK edge when VSYNC is low and HREF is high
*

TODO
====
Finish Writing.




## Tweakable internal parameters
