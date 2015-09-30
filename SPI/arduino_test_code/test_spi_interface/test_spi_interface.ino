/**
 * \project test_spi
 * \author Joshua Vasquez
 * \date September 2015
 */

#include "preamble.h"
#include <SPI.h>

#define CS 10

void setup()
{
    Serial.begin(115200);

/// Print build information.
    preamble();
    pinMode(CS, OUTPUT);
    digitalWrite(CS, HIGH);
    SPI.begin();
    SPI.setClockDivider(SPI_CLOCK_DIV64);
    delay(1000);

}


void loop()
{
    static uint8_t i = 0;
    digitalWrite(CS, HIGH);
    digitalWrite(CS, LOW);
        SPI.transfer(i);
        delayMicroseconds(10);
    digitalWrite(CS, HIGH);
    delay(100);
    ++i;
}
