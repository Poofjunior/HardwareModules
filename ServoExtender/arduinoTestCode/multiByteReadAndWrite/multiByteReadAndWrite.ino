/**
 * SPI test sketch for the SPI slave module
 * \author Joshua Vasquez
 * \date September 2014
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
  SPI.setClockDivider(255);  // Input up to 255 to slow down SPI clock speed.
  SPI.setDataMode(SPI_MODE0);
  
  Serial.begin(115200);
}


void loop() {
  // Perform an 8-bit Transfer:
  Serial.println("Enter the reg to read from:");
  while(!Serial.available());
  unsigned char dataToTransfer = Serial.read() - 48;
  Serial.print("You entered: ");
  Serial.println(dataToTransfer);
  
  if (dataToTransfer <= 127)
  {
    // Begin Read:
    digitalWrite(CS, LOW);
    delay(1);  // TODO: remove this later.
    unsigned char dataIn = SPI.transfer(0x07);
    delay(1);
    digitalWrite(CS,HIGH);
  
    Serial.print("Data read from reg: ");
    //Serial.print(dataToTransfer);
    Serial.print(" is: ");
    Serial.println(dataIn, DEC);
    Serial.println();  
  }
}

