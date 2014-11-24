/**
 * spiWriteData.ino
 * Joshua Vasquez
 * November 22, 2014
 *
 * \note Standard digitalWrite commands limit the maximum SPI transfer rate to
 *       SPI_CLK_DIV = 8 on the FPGA side. The (DUE) Arduino's WE_O and STB_O
 *       output signals take TOO LONG to bring low again after they are 
 *       asserted.
 */

#define STB_O 16
#define WE_O 17
#define RST_O 18
#define ACK_I 19


// LSb to MSb
const int dataOutPins[] = {9, 8, 7, 6, 5, 4, 3, 2};
const int addrPins[] = {39, 41, 43, 45, 47, 49, 51, 53};

/// Prototypes:
void writeParallel( int* pins, int8_t val);
int8_t readParallel( int* pins);
void resetSPI_Wishbone();


void setup()
{
    pinMode(STB_O, OUTPUT);
    pinMode(WE_O, OUTPUT);
    pinMode(RST_O, OUTPUT);
    pinMode(ACK_I, INPUT);

    for (int i = 0; i < 8; ++i)
    {
        pinMode(dataOutPins[i], OUTPUT);
        pinMode(addrPins[i], OUTPUT);
    }
    
}


void loop()
{
    int FPGA_Busy;

    digitalWrite(WE_O, LOW);
    digitalWrite(STB_O, LOW);
    resetSPI_Wishbone();

/// Write the Chip-select pin and assert the CSHOLD bit.
    writeParallel(addrPins, 0x80);

    for (uint8_t i = 0; i < 100; ++i)
    {
        // signal end-of-transfer before sending the last value.
        if (i == 99)
            writeParallel(addrPins, 0x00);

        /// Load the data to be sent.
        writeParallel(dataOutPins, i);

        initTransfer();
/*
        /// Wait until FPGA is ready to receive more data.
        do {
            FPGA_Busy = digitalRead(RTY_I); 
        }
        while(FPGA_Busy);
*/

    }
}



void writeParallel(const int* pins, int8_t val)
{
    for(int i = 0; i < 8; ++i) 
    {
        digitalWrite(pins[i], (val & 0x00000001));
        val = val >> 1;
    }
}

int8_t readParallel(const int* pins)
{
    int8_t val = digitalRead(pins[0]);

    for(int i=1; i<8; i++) {
        val |= (digitalRead(pins[i]) << i);
    }
    return val;
}

void resetSPI_Wishbone()
{
    digitalWrite(RST_O, HIGH);
    delay(100);
    digitalWrite(RST_O, LOW);
    delay(100);
}

void initTransfer()
{
    digitalWrite(WE_O, HIGH);
    digitalWrite(STB_O, HIGH);
    //delayMicroseconds(1);
    digitalWrite(WE_O, LOW);
    digitalWrite(STB_O, LOW);
    //delayMicroseconds(1);
}
