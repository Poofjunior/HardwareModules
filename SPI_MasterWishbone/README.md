SPI Master Wishbone
========

This module is a wishbone-compatible SPI Master. Single Transfers and multiple
transfers are supported.

Three devices are supported with individual chip-selects; however, the 
wishbone 8-bit address
space provides support for up to 128 devices. 

Data is transferred from the Wishbone-defined 8-bit data bus.

The Wishbone 8-bit address encodes the following information:

|MSbit|bits[6:0]|
|-----|---------|
| CSHOLD | ChipSelect[6:0] |


The CSHOLD bit indicates whether or not to release (bring back to 1) the slave 
following a completed 8-bit transfer.

To transfer a single byte to a slave device, set the Wishbone address to the
corresponding chip-select of that device, and do not set the CSHOLD bit. Data
will be captured from the Wishbone data bus and written over SPI to the 
corresponding slave.

In a multi-byte transfer to a single device, set the CSHOLD bit for each
byte sent except the last byte.

If the address changes while the CSHOLD bit was previously set, the chip-select
line of the previously-addressed device will be released, and the chip-select
of the new address will be brought low.

## Tweakable internal parameters
* **clkDiv**: the clock divider signal. default is 4.
