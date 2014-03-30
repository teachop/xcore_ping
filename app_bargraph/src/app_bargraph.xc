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
// seven_seg - print on sparkfun 4 digit 7-segment display
//
void seven_seg(port txd, streaming chanend comm) {
    const uint32_t bit_rate = (100*1000*1000)/9600;
    uint32_t latest_value;
    uint32_t value_updated = 0;
    uint32_t tx_count = 0;
    uint8_t buffer[8];
    buffer[0] = 'w'; // 4 == decimal point 3rd digit
    buffer[1] = 4;
    buffer[2] = 'y'; // 0 == goto left-most digit
    for( uint32_t loop=3; loop<sizeof(buffer); ++loop ) {
        buffer[loop] = 0;
    }

    const uint32_t display_update = 200*1000*100;
    timer tick;
    uint32_t next_tick;
    tick :> next_tick;

    while (1) {
        select {
        case comm :> latest_value:
            latest_value = (9999<latest_value)? 9999 : latest_value;
            value_updated = 1;
            break;
        case tick when timerafter(next_tick) :> void:
            if ( !tx_count && value_updated ) {
                // build data string for display
                for ( uint32_t loop=0; loop<4; ++loop ) {
                    uint8_t digit = ((2>loop) || latest_value)? '0' + latest_value%10 : ' ';
                    buffer[sizeof(buffer)-1-loop] = digit;
                    latest_value /= 10;
                }
                tx_count = sizeof(buffer);
                value_updated = 0;
            }
            if ( tx_count ) {
                uint16_t delay_count;
                // sync counter then start bit low
                txd <: 1 @ delay_count;
                delay_count += bit_rate;
                txd @ delay_count <: 0;
                uint8_t shifter = buffer[sizeof(buffer)-tx_count];
                for ( uint32_t bit=0; bit<8; ++bit ) {
                    // data bits
                    delay_count += bit_rate;
                    txd @ delay_count <: shifter;
                    shifter >>= 1;
                }
                // stop bit high
                delay_count += bit_rate;
                txd @ delay_count <: 1;
                tx_count--;
            } else {
                // pause
                next_tick += display_update;
            }
            break;
        }
    }
}


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
void bargraph_task(interface ping_if client sensor, interface neopixel_if client strip, streaming chanend comm) {
    uint8_t r,g,b;
    uint8_t rolling = 0;
    uint32_t leds = strip.numPixels();
    uint32_t center = leds/2;
    const uint32_t fade_band = 5;// < 9, 0 disables
    const uint32_t length_mm = 1000;
    // set 1 meter range, 50mSec, 4 samples, toss 2 on lost echo
    sensor.setFilter(length_mm, 50, 4, 2);
    
    // redraw delay must be > (100 * (30*leds + (leds>>2) + 51))
    const uint32_t tick_rate = 5000*100;
    timer tick;
    uint32_t next_tick;
    tick :> next_tick;

    while (1) {
        select {
        case tick when timerafter(next_tick) :> void:
            next_tick += tick_rate;
            uint32_t current_distance = sensor.getDistance();
            if ( length_mm >= current_distance ) {
                comm <: current_distance;
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
    streaming chan comm;

    par {
        neopixel_task(led_pin, neopixel_strip);
        bargraph_task(ping_sensor, neopixel_strip, comm);
        ping_task(trig_pin, echo_pin, ping_sensor);
        seven_seg(txd_pin, comm);
    }

    return 0;
}

