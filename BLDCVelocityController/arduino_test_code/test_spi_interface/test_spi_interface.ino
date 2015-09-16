/**
 * \project test_spi
 * \author Joshua Vasquez
 * \date September 2015
 */

#include "preamble.h"
#include <SPI.h>

void setup()
{
  Serial.begin(115200);

/// Print build information.
  preamble();

  delay(2000);
}


void loop()
{

}
