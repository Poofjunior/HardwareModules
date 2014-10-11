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
  //SPI.setClockDivider(84);  // Input up to 255 to slow down SPI clock speed.
  SPI.setDataMode(SPI_MODE0);
  
  Serial.begin(115200);
}


void loop() {
  // Perform an 8-bit Transfer:
  while(!Serial.available());
  char dataToTransfer = Serial.read();
 
  digitalWrite(CS, LOW);

  delay(1);
  char dataIn = SPI.transfer(dataToTransfer);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(1);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(2);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(3);
  Serial.println(dataIn, DEC);  
  delay(1);
  digitalWrite(CS,HIGH);
  
  Serial.println();  
}


