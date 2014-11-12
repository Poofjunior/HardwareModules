demux
========

an open-drain demultiplexer ideal for use in I2C communication where multiple
devices share the same address. 

Note that external pullups are required on both input and output.

Note that clock stretching for I2C devices is not possible in the current 
design since the demultiplexed output is not bidirectional.

![open drain demux](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/demux/demux_SynthesizedOutput.png)

See [this](http://www.onsemi.com/pub/Collateral/AND9061-D.PDF) application 
note by OnSemi for more details on use specifically in I2C demultiplexing.

