SPI Master Wishbone
========
## Top-Level View
![Top Level View](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/SPI_MasterWishbone/SPI_MasterWishboneSynthesizedOutput.png)

## Overview
This module is a wishbone-compatible SPI Master. Single Transfers and multiple
transfers are supported.

Up to 128 devices are supported with individual chip-selects. This limit is 
imposed by the wishbone 8-bit address space. Additional chip-selects are 
supportable with a wider address space (i.e: 16, 32, or 64).

The desired number of chip select outputs is parameterizable at the top
level module.  (Image below shows 3 outputs)

## Details
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

### Detailed View
![Detailed View](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/SPI_MasterWishbone/SPI_MasterWishboneSynthesizedOutputDetail.png)

## Tweakable internal parameters
* **clkDivider**: the clock divider signal. default is 4.
