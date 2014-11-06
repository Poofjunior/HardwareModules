/**
 * pollEncoders.ino
 * \author Joshua Vasquez
 * \date November 2014
 */

/**
 * \note Test sketch intended for Arduino DUE platform only. This code can be
 *       easily ported to another Arduino model; however, note that a logic
 *       level shifter must be used to convert output 5[V] signals from the 
 *       Arduino to 3.3[V] input signals to the FPGA.
 */

#include <SPI.h>

#define CS 13

void setup() {
  pinMode(CS, OUTPUT);
  digitalWrite(CS, HIGH);
  SPI.begin();
  //SPI.setClockDivider(255);  // optional arg up to 255 to slow down SPI clock speed.
  SPI.setDataMode(SPI_MODE0);
  
  Serial.begin(115200);
}


void loop() {
  // Perform an 8-bit Transfer:
    int32_t encoderA = 0;  
    int32_t encoderB = 0;  

    // Begin Read:
    digitalWrite(CS, LOW);

    SPI.transfer(0x00); // Transfer starting register.
    
    for (uint8_t i = 0; i < 4; ++i)
        encoderA = (encoderA  << 8) | SPI.transfer(0xff);

    for (uint8_t j = 0; j < 4; ++j)
        encoderB = (encoderB  << 8) | SPI.transfer(0xff);

    digitalWrite(CS, HIGH); // End SPI transfer.

    Serial.print("encoderA: ");  
    Serial.println(encoderA);  
    Serial.print("encoderB: ");  
    Serial.println(encoderB);  
    Serial.println();  
    delay(100);
}

