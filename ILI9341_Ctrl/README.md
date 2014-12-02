ILI9341_Ctrl
========
## Overview
This module is an ILI9341 driver designed for easily dumping data to the 
screen. 

Currently, pixel data is stored in an internal block of ram, but this ram will
eventually be moved outside the module and be a feature to be implemented by
the user.

TODO
====
Possibly make this module wishbone-compatible.




## Tweakable internal parameters
* **SPI_CLK_DIV**: the spi prescaler signal. default is 0 (i.e: 25 [MHz]).
