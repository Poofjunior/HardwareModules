ServoPWM
========

Quadrature Rotary Encoders output a grey coded waveform when spun. This pattern
can be decrypted by a four-state finite-state machine implemented in 
digital logic.

![Encoder Waveform](http://joshuavasquez.com/docs/assets/img/Tutorials/OpticalRotaryEncoderTheory/waveformCropped.png)

### Synthesized Output
![Quadrature encoder hardware](https://raw.githubusercontent.com/Poofjunior/HardwareModules/master/QuadratureEncoder/QuadratureEncoderSynthesizedOutput.png)

Note: The version of Quartus II that I'm using displays constants in the RTL 
viewer in (left-to-right) least-significant bit to most significant bit. 

Note also that not all 32 multiplexers are shown.
