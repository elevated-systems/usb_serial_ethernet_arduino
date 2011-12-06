/*
 Chat  Server
 
 A simple server that distributes any incoming messages to all
 connected clients.  To use telnet to  your device's IP address and type.
 You can see the client's input in the serial monitor as well.
 Using an Arduino Wiznet Ethernet shield. 
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 * Analog inputs attached to pins A0 through A5 (optional)
 
 created 18 Dec 2009
 by David A. Mellis
 modified 10 August 2010
 by Tom Igoe
 
 */

#include <avrpins.h>
#include <max3421e.h>
#include <usbhost.h>
#include <usb_ch9.h>
#include <Usb.h>
#include <usbhub.h>
#include <avr/pgmspace.h>
#include <address.h>

#include <cdcftdi.h>

#include <printhex.h>
#include <message.h>
#include <hexdump.h>
#include <parsetools.h>

#include <SPI.h>
#include <Ethernet.h>

class FTDIAsync : public FTDIAsyncOper
{
public:
    virtual uint8_t OnInit(FTDI *pftdi);
};

uint8_t FTDIAsync::OnInit(FTDI *pftdi)
{
    uint8_t rcode = 0;
    
    rcode = pftdi->SetBaudRate(115200);

    if (rcode)
    {
        ErrorMessage<uint8_t>(PSTR("SetBaudRate"), rcode);
        return rcode;
    }
    rcode = pftdi->SetFlowControl(FTDI_SIO_DISABLE_FLOW_CTRL);
    
    if (rcode)
        ErrorMessage<uint8_t>(PSTR("SetFlowControl"), rcode);
            
    return rcode;
}

USB              Usb;
FTDIAsync        FtdiAsync;
FTDI             Ftdi(&Usb, &FtdiAsync);

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network.
// gateway and subnet are optional:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,1, 10 };
byte gateway[] = { 192,168,1, 1 };
byte subnet[] = { 255, 255, 255, 0 };

// telnet defaults to port 23
Server server(23);
uint8_t rcode = 0;

char ip_to_serial = '\0';
char serial_to_ip = '\0';
boolean new_ip_to_serial = false;
boolean new_serial_to_ip = false;

void setup() {
  Serial.begin( 115200 );
  Serial.println("Start");
  //Initialize USB, warn if there's a problem with init.
  if (Usb.Init() == -1)
      Serial.println("OSC did not start."); 
  //Initialize Ethernet
  Ethernet.begin(mac, ip, gateway, subnet);
  //and start listening for clients
  server.begin();
}

void loop() {
  Usb.Task();
  if( Usb.getUsbTaskState() == USB_STATE_RUNNING )
  {  
    if (new_ip_to_serial)
    {
        Serial.print("Outgoing Serial data: ");
        Serial.println(ip_to_serial);
        rcode = Ftdi.SndData(1, (uint8_t*)&ip_to_serial);
        ip_to_serial = '\0';
        new_ip_to_serial = false;
        if (rcode)
          ErrorMessage<uint8_t>(PSTR("SndData"), rcode);
        delay(50);
    }
        
    uint8_t  in_buf[3];
    uint16_t rcvd = 3;
    rcode = Ftdi.RcvData(&rcvd, in_buf);
        
    if (rcode && rcode != hrNAK)
      ErrorMessage<uint8_t>(PSTR("RcvData"), rcode);
            
    // The device reserves the first two bytes of data
    // to contain the current values of the modem and line status registers.
    if (rcvd > 2)
      {        
        new_serial_to_ip = true;
        serial_to_ip = (char) in_buf[2];
        Serial.print("Incoming Serial data: ");
        Serial.println(serial_to_ip);
      }
  }
  
  Client client = server.available();
  if (client) //if incoming data
  {
    // read the byte incoming from the client:
    ip_to_serial = client.read();
    new_ip_to_serial = true;
    Serial.print("Incoming IP data: ");
    Serial.println(ip_to_serial);
  }
  if (new_serial_to_ip) //if outgoing data
  {
    server.print(serial_to_ip); //send to all devices connected to server
    Serial.print("Outgoing IP data: ");
    Serial.println(serial_to_ip);
    serial_to_ip = '\0';
    new_serial_to_ip = false;
  } 
}
