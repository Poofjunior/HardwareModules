SPI EncoderReader
========
This logic block reads two quadrature encoders and outputs their data over
an SPI bus. In this case, the FPGA poses as an SPI slave.

Data is stored in the FPGA's "memory" and transferred sequentially beginning 
from the starting register. The starting register is the first byte sent over
by the master in an SPI transfer. 
To access the encoder data with a microcontroller, perform an spi transmission
in the following form:
    
    Master writes cs low.
    Master writes starting reg 0x00 to access the beg
    Master reads four bytes and assembles to form a 32-bit int. (encoderA)
    Master reads four more bytes and assembles to form a 32-bit int. (encoderB)
    Master writes cs high.
    
### Synthesized Output
![Quadrature encoder spi slave hardware](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/SPI_EncoderReader/SPI_EncoderReader_SynthesizedOutput.png)

Note: The version of Quartus II that I'm using displays constants in the RTL 
viewer in (left-to-right) least-significant bit to most significant bit. 
