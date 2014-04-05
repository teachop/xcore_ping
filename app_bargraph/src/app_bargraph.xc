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
#include "seven_seg.h"


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
void bargraph_task(interface ping_if client sensor, interface neopixel_if client strip, interface seven_seg_if client display) {
    uint8_t r,g,b;
    uint8_t rolling = 0;
    uint32_t display_busy = 0;
    uint32_t leds = strip.numPixels();
    uint32_t center = leds/2;
    uint32_t short_strip = (16 >= leds);
    const uint32_t fade_band = short_strip? 2:5;// < 9, 0 disables
    const uint32_t length_mm = short_strip? 500:1000;
    strip.setBrightness(short_strip? 63:255);
    // set range, sample rate, averaging, toss 2 on lost echo
    sensor.setFilter(length_mm, 50, 4, 2);
    
    // redraw delay must be > (100 * (30*leds + (leds>>2) + 51))
    const uint32_t tick_rate = 5000*100;
    timer tick;
    uint32_t next_tick;
    tick :> next_tick;

    while (1) {
        select {
        case display.written():
                display_busy = 0;
            break;
        case tick when timerafter(next_tick) :> void:
            next_tick += tick_rate;
            uint32_t current_distance = sensor.getDistance();
            if ( length_mm >= current_distance ) {
                if ( !display_busy ) {
                    display.setValue( current_distance, 1, 0 );
                    display_busy = 1;
                }
                uint32_t led_count = (100*current_distance) / (100*length_mm/leds);
                if ( center != led_count ) {
                    led_count = (led_count>=leds)? leds-1 : led_count;
                    center = (led_count>center)? center+1 : center-1;
                }
            }
            rolling++;
            for ( uint32_t pixel=0; pixel<leds; ++pixel) {
                {r,g,b} = wheel(pixel*256/leds + rolling);
                uint8_t fade = (center>pixel)? (center-pixel) : (pixel-center);
                fade = (fade_band<fade)? 8 : fade;
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
port trig_pin = XS1_PORT_1J; // j7.10
port echo_pin = XS1_PORT_1K; // j7.11
port led_pin  = XS1_PORT_1M; // j7.15
port txd_pin  = XS1_PORT_4C; // j7.5 (6,7,8)

int main() {
    interface neopixel_if neopixel_strip;
    interface ping_if ping_sensor;
    interface seven_seg_if display;

    par {
        neopixel_task(led_pin, neopixel_strip);
        bargraph_task(ping_sensor, neopixel_strip, display);
        ping_task(trig_pin, echo_pin, ping_sensor);
        seven_seg_task(txd_pin, display);
    }

    return 0;
}

