/**
 * demuxSweep.ino
 * \author Joshua Vasquez
 * \date November 2014
 */

/**
 * \note Test sketch intended for Arduino DUE platform only. This code can be
 *       easily ported to another Arduino model; however, note that a logic
 *       level shifter must be used to convert output 5[V] signals from the 
 *       Arduino to 3.3[V] input signals to the FPGA.
 */

#define CS 13

void setup() {
    pinMode(2, OUTPUT);
    pinMode(3, OUTPUT);
    pinMode(4, OUTPUT);
}


void loop() {
    for (uint8_t i = 0; i < 8; ++i)
    {
        digitalWrite(2, 0x01 & i);
        digitalWrite(3, 0x01 & (i >> 1) );
        digitalWrite(4, 0x01 & (i >> 2) );
        delay(50);
    }
    for (int8_t j = 7; j >= 0; --j) // uint8_t will never satisfy end loop case
    {
        digitalWrite(2, 0x01 & j);
        digitalWrite(3, 0x01 & (j >> 1) );
        digitalWrite(4, 0x01 & (j >> 2) );
        delay(50);
    }
}

