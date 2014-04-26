//-----------------------------------------------------------
// XCore Ping Sensor Test application
// by teachop
//
// Read distance and show on a serial display.
//

#include <xs1.h>
#include <timer.h>
#include <stdint.h>
#include "ping.h"
#include "seven_seg.h"


// ---------------------------------------------------------------
// distance_task - display ping sensor reading on serial led display
//
void distance_task(interface ping_if client sensor, interface seven_seg_if client display) {
    uint32_t display_busy = 0;
    const uint32_t length_mm = 1000; // maximum distance to accept
    
    // redraw delay
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
            }
            break;
        }
    }
}


// ---------------------------------------------------------
// main - xCore ping sensor test
//
port trig_pin = XS1_PORT_1J; // j7.10
port echo_pin = XS1_PORT_1K; // j7.11
port txd_pin  = XS1_PORT_4C; // j7.5 (6,7,8)

int main() {
    interface ping_if ping_sensor;
    interface seven_seg_if display;

    par {
        distance_task(ping_sensor, display);
        ping_task(trig_pin, echo_pin, ping_sensor);
        seven_seg_task(txd_pin, 9600, display);
    }

    return 0;
}

