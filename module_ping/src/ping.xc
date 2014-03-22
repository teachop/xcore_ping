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
    uint32_t speed = 60*1000*100;
    uint32_t filter = 1;
    uint32_t lost_pulse = 0;
    uint32_t latest_distance = 0;
    uint32_t measurement_limit = 100;
    uint32_t pin_state, enable;
    uint32_t buffer[MAX_SAMPLES];

    timer tick;
    uint32_t next_pass;
    tick :> next_pass;
    uint32_t start_time = next_pass;

    while( 1 ) {
        select {
        case tick when timerafter(next_pass) :> void:
            next_pass += speed;
            uint32_t delay_count;
            // generate the trigger output pulse
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
                // echo pulse is high
                start_time = now;
            } else {
                // echo pulse is low
                uint32_t reading = (now-start_time) / 5800;//cm
                if ( measurement_limit <= reading ) {
                    lost_pulse = 2;
                }
                // when out of range or lost, use last raw reading
                if ( lost_pulse ) {
                    reading = buffer[0];
                    lost_pulse--;
                }
                uint32_t accum = reading;
                if ( 1 < filter ) {
                    for ( int loop=(filter-1); loop; --loop ) {
                        buffer[loop] = buffer[loop-1];
                        accum += buffer[loop];
                    }
                }
                buffer[0] = reading;
                latest_distance = accum / filter;
                enable = 0;
            }
            break;
        case dvr.getDistance() -> uint32_t return_val:
            return_val = latest_distance;
            break;
        case dvr.setFilter(uint32_t max_distance, uint32_t rate, uint32_t samples):
                measurement_limit = max_distance;
            if ( samples && (MAX_SAMPLES >= samples) ) {
                filter = samples; // must != 0
            }
            if ( 10 <= rate ) {
                // data sheet recommends >= 60!
                speed = rate * 1000 * 100;
            }
            break;
        }
    }

}
