/* USB Host to PL2303-based USB GPS unit interface */
/* Navibee GM720 receiver - Sirf Star III */
/* USB support */
#include <avrpins.h>
#include <max3421e.h>
#include <usbhost.h>
#include <usb_ch9.h>
#include <Usb.h>
#include <usbhub.h>
#include <avr/pgmspace.h>
#include <address.h>
/* CDC support */
#include <cdcftdi.h>
/* Debug support */
#include <printhex.h>
#include <message.h>
#include <hexdump.h>
#include <parsetools.h>
class MyFTDIAsyncOper : public FTDIAsyncOper
{
  public:
    virtual uint8_t OnInit(FTDI *pftdi);
};

uint8_t MyFTDIAsyncOper::OnInit(FTDI *pftdi)
{}

USB     Usb;
//USBHub     Hub(&Usb);
MyFTDIAsyncOper  AsyncOper;
FTDI           Ftdi(&Usb, &AsyncOper);

void setup()
{
  Serial.begin( 115200 );
  Serial.println("Start");

  if (Usb.Init() == -1)
      Serial.println("OSCOKIRQ failed to assert");
  Ftdi.SetBaudRate(115200);
  delay( 200 ); 
}

void loop()
{
    Usb.Task();
  
    if( Usb.getUsbTaskState() == USB_STATE_RUNNING )
    {  
       uint8_t rcode;
       uint8_t  buf[64];    //serial buffer equals Max.packet size of bulk-IN endpoint           
       uint16_t rcvd = 64;      
       /* reading the GPS */
       rcode = Ftdi.RcvData(&rcvd, buf);
        if ( rcode && rcode != hrNAK )
           ErrorMessage<uint8_t>(PSTR("Ret"), rcode);            
            if( rcvd ) { //more than zero bytes received
              for( uint16_t i=0; i < rcvd; i++ ) {
                  Serial.print(buf[i]); //printing on the screen
              }//for( uint16_t i=0; i < rcvd; i++...              
            }//if( rcvd
        //delay(10);            
    }//if( Usb.getUsbTaskState() == USB_STATE_RUNNING..    
}


