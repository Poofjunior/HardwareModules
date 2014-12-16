OV7670_Stream
========
## Overview
This module combines the OV7670 driver and the ILI9341 driver to stream the
data out of the OV7670 and onto the display at 30FPS.

Note: this project has been done with Altera tools but may be transposed to 
another FPGA vendors' tools.

## Details
* Cyclone IV input clock speed: 50 [MHz], from DE0 Nano onboard clock in PIN_R8
* PLL output clock speed: 100 [MHz], used to bump SPI transmissions up to 50 [MHz]
* Camera PCLK speed: 25 MHz


TODO
====
Finish Writing.




## Tweakable internal parameters
