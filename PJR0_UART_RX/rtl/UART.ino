/*###########################################################################
//# G0B1T: HDL SERIAL COMMUNICATION PROTOCOLS. 2020.
//###########################################################################
//# Copyright (C) 2020. F.A.Acosta David   (FAD) fa.acostad@uniandes.edu.co
//# 
//# This program is free software: you can redistribute it and/or modify
//# it under the terms of the GNU General Public License as published by
//# the Free Software Foundation, version 3 of the License.
//#
//# This program is distributed in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//# GNU General Public License for more details.
//#
//# You should have received a copy of the GNU General Public License
//# along with this program.  If not, see <http://www.gnu.org/licenses/>
//#########################################################################*/
//===========================================================================
//  LIBRARIES
//===========================================================================
#include <SoftwareSerial.h>

//===========================================================================
//  VARIABLE Declarations
//===========================================================================
//////////// READ ////////////
unsigned char dataRead;
unsigned char newData;
//////////// WRITE ////////////
unsigned char dataWrite = 0;

//The circuit:
// RX is digital pin 3 (connect to TX of other device)
// TX is digital pin 2 (connect to RX of other device)
SoftwareSerial mySerial(3, 2); // RX, TX

//===========================================================================
//  SETUP Coding
//===========================================================================
// Setup code here, to run once
void setup() 
{
  // Opens serial communications and waits for port to open
  mySerial.begin(115200);
  Serial.begin(115200);
  while (!Serial)
  {
    ; // Waits for serial port to connect. Needed for Native USB only
  }
  // Serial.println("First message");
}

//===========================================================================
//  LOOP Coding
//===========================================================================
// Main code here, to run repeatedly
void loop() 
{
  if (Serial.availableForWrite())
  {
    Serial.write(dataWrite);
    dataWrite = dataWrite + 1;
    if (mySerial.available() > 0)
      {
        mySerial.println(dataWrite);
      }
  }
  if (Serial.available() > 0)
  {
    dataRead = Serial.read();
    if (mySerial.available() > 0)
    {
      mySerial.print("Dec: ");
      mySerial.print(dataRead); 
      mySerial.print(" Bin: ");
      bitArray(dataRead);
      
      // Reads the input on analog pin 0 as the new data signal
      newData = analogRead(A0);
      // Converts the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V)
      newData = newData * (5.0 / 1023.0);
      // Prints out the value you read
      mySerial.print(" newData: ");
      mySerial.println(newData);
      mySerial.println(" ");
    }
  }
  delay(500);
}

//===========================================================================
//  FUNCTIONS
//===========================================================================
// Changes the format from decimal to a binary array
void bitArray (unsigned char uint)
{
  int counter = 0;
  unsigned char binaryDigit;
  while (counter < 8)
  {
    if (uint & (1 << (7 - counter)))
    {
      binaryDigit = 1;
    }
    else
    {
      binaryDigit = 0;
    }
    mySerial.print(binaryDigit);
    counter += 1;
  }
}
