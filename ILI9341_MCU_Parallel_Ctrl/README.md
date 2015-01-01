ILI9341_MCU_Parallel_Ctrl
========
## Overview
This module is an ILI9341 driver designed for easily dumping data to the 
screen with an FPGA. 

This driver should work "out-of-the-box" with 
[Adafruit's](http://www.adafruit.com/products/1770) 2.8[in] TFT display.

Note: IM0-IM3 must all be pulled low

Currently, pixel data is stored in an internal block of ram, but this ram will
eventually be moved outside the module and be a feature to be implemented by
the user.

## Basic Usage
The main driver block (ILI9341_8080_I_Driver) that outputs a screen 
initialization sequence and then outputs pixel data over the parallel interface
whenever the **dataReady** input is high and the block has strobed out the 
previous data. An optional auto-incrementing address is output from this block
such that pixel data may be fetched from a separate ram block.

## Details
The initialization settings written to the ILI9341 convert the screen rotation
to landscape. If this behaviour is not desired, you may change the settings in 
the memData.mif file directly.

Configuration Data is stored in a 9-bit wide address. Setting the MSbit (bit 8) 
indicates that the 8-bit value is a command, not data.

## Development
From the ILI9341 datasheet, a single write cycle is shown below:


TODO
====
Possibly make this module wishbone-compatible.




## Tweakable internal parameters
