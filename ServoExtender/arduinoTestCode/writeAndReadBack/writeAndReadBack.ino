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
  while(!Serial.available());
  char dataToTransfer = Serial.read() - 48;
  Serial.print("Write four zeros starting from reg: ");
  Serial.println(dataToTransfer, DEC);
  // Perform an 8-bit Transfer:

  digitalWrite(CS, LOW);
  delay(10);
  SPI.transfer(0x80 | dataToTransfer);
  char dataIn = SPI.transfer(0);
  //Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  //Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  //Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  //Serial.println(dataIn, DEC);  
  delay(10);
  digitalWrite(CS,HIGH);
  
  delay(10);
  
  digitalWrite(CS, LOW);
  Serial.print("Reading back memory starting from reg: ");
  Serial.println(dataToTransfer);
  SPI.transfer(dataToTransfer);
  dataIn = SPI.transfer(0);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  Serial.println(dataIn, DEC);  
  dataIn = SPI.transfer(0);
  Serial.println(dataIn, DEC);  
  
  digitalWrite(CS, HIGH);
  
  Serial.println();  
}


