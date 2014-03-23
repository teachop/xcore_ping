//---------------------------------------------------------
// Ping sensor driver
// by teachop
//

#include <xs1.h>
#include <stdint.h>
#include "ping.h"


// ---------------------------------------------------------
// ping_task - ultrasonic distance sensor driver for HC-SR04
//
void ping_task(port trigger, port pulse, interface ping_if server dvr) {
    uint32_t tick_rate = 60*1000*100;
    uint32_t filter = 1;
    uint32_t filtered_distance = 0;
    uint32_t measurement_limit = 1000;
    uint32_t pin_state, enable;
    uint32_t buffer[MAX_SAMPLES];

    timer tick;
    uint32_t next_tick;
    tick :> next_tick;
    uint32_t start_time = next_tick;

    while( 1 ) {
        select {
        case tick when timerafter(next_tick) :> void:
            next_tick += tick_rate;
            uint32_t delay_count;
            // generate 10usec trigger output
            trigger <: 1 @ delay_count;
            delay_count += 10*100;
            trigger @ delay_count <: 0;
            pin_state = 0;
            enable = 1;
            break;
        case enable => pulse when pinsneq(pin_state) :> pin_state:
            uint32_t now;
            tick :> now;
            if ( pin_state ) {
                // echo pulse went high
                start_time = now;
            } else {
                // echo pulse is low
                uint32_t reading = (now-start_time) / 580;//mm
                if ( measurement_limit < reading ) {
                    // when out of range or lost, use last raw reading
                    reading = buffer[0];
                }
                uint32_t accum = reading;
                for ( int loop=(filter-1); loop; --loop ) {
                    buffer[loop] = buffer[loop-1];
                    accum += buffer[loop];
                }
                buffer[0] = reading;
                filtered_distance = accum / filter;
                enable = 0;
            }
            break;
        case dvr.getDistance() -> uint32_t return_val:
            return_val = filtered_distance;
            break;
        case dvr.setFilter(uint32_t max_range, uint32_t rate, uint32_t samples):
            measurement_limit = max_range;
            if ( samples && (MAX_SAMPLES >= samples) ) {
                filter = samples; // must != 0
            }
            if ( 10 <= rate ) {
                tick_rate = rate * 1000 * 100;
            }
            break;
        }
    }

}
