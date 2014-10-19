ServoPWM
========

Hobby RC servos implement a distinctly different pwm signal called 
pulse-position modulation (ppm). For servo PPM, the width of the initial pulse
carries information about the desired angle as shown in the image below:

![RC servo signal image](http://bansky.net/blog_stuff/images/servo_pulse_width.png)

This module accepts an 8-bit input (0 through 255) which linearly maps to a 
duty cycle value from 0 to 100%. As with the image above, 0 maps to a 0.5 [ms] 
wide pulse, and 255 maps to a 2.5 [ms] pulse. 
