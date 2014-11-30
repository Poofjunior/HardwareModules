ILI9341_Ctrl
========
## Overview
This module is a wishbone-compatible ILI9341 driver. 

TODO
====
The Wishbone 8-bit address encodes the following information:

|MSbit|bits[6:0]|
|-----|---------|
| ?? | ?? |



## Tweakable internal parameters
* **SPI_CLK_DIV**: the spi prescaler signal. default is 0 (i.e: 25 [MHz]).
