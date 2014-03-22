//-----------------------------------------------------------
// XCore Ping Sensor Test application
// by teachop
//
// Read distance and display on a NeoPixel strip.
//

#include <xs1.h>
#include <timer.h>
#include <stdint.h>
#include "neopixel.h"
#include "ping.h"


// ---------------------------------------------------------
// wheel - input a value 0 to 255 to get a color value.
//         The colors are a transition r - g - b - back to r
//
{uint8_t, uint8_t, uint8_t} wheel(uint8_t wheelPos) {
    if ( wheelPos < 85 ) {
        return {wheelPos*3, 255-wheelPos*3, 0};
    } else if ( wheelPos < 170 ) {
        wheelPos -= 85;
        return {255-wheelPos*3, 0, wheelPos*3};
    } else {
        wheelPos -= 170;
        return {0, wheelPos*3, 255-wheelPos*3};
    }
}


// ---------------------------------------------------------------
// bargraph_task - display ping sensor reading on an led bargraph
//
void bargraph_task(interface ping_if client sensor, interface neopixel_if client strip) {
    uint8_t r,g,b;
    uint8_t rolling = 0;
    uint32_t length = strip.numPixels();
    uint32_t center = length/2;
    const uint32_t maximum = 100; // set 1 meter active range limit
    
    // this is the update rate for the bargraph
    uint32_t speed = ((30*length + (length>>2) + 51) + 5000)*100;

    sensor.setFilter(maximum,10,8);

    timer tick;
    uint32_t next_pass;
    tick :> next_pass;

    while (1) {
        select {
        case tick when timerafter(next_pass) :> void:
            next_pass += speed;
            uint32_t current_distance = sensor.getDistance();
            if ( (0<current_distance) && (maximum>current_distance) ) {
                uint32_t led_count = (100*current_distance) / (100*100/length);
                if ( center != led_count ) {
                    led_count = (led_count>=length)? length-1 : led_count;
                    center = (led_count>center)? center+1 : center-1;
                }
            }
            rolling++;
            for ( uint32_t pixel=0; pixel<length; ++pixel) {
                {r,g,b} = wheel((pixel*256/length + rolling) & 255);
                uint8_t fade = (center>pixel)? (center-pixel) : (pixel-center);
                fade = (5<fade)? 8 : fade;
                strip.setPixelColorRGB( pixel, r>>fade,g>>fade,b>>fade);
            }
            strip.show();
            break;
        }
    }
}


// ---------------------------------------------------------
// main - xCore ping sensor test
//
port trig_pin = XS1_PORT_1F; // j7.1
port echo_pin = XS1_PORT_1H; // j7.2
port led_pin  = XS1_PORT_1G; // j7.3

int main() {
    interface neopixel_if neopixel_strip;
    interface ping_if ping_sensor;

    par {
        neopixel_task(led_pin, neopixel_strip);
        bargraph_task(ping_sensor, neopixel_strip);
        ping_task(trig_pin, echo_pin, ping_sensor);
    }

    return 0;
}

