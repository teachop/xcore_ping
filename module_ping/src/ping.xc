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
    uint32_t latest_distance = 0;
    uint32_t pin_state, enable;

    timer tick;
    uint32_t start_time, end_time;
    uint32_t next_pass;
    tick :> next_pass;

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
            if ( pin_state ) {
                // echo pulse is high
                tick :> start_time;
            } else {
                tick :> end_time;
                // echo pulse is low
                latest_distance = (end_time-start_time) / 5800;//cm
                // TODO - filtering
                enable = 0;
            }
            break;
        case dvr.getDistance() -> uint32_t return_val:
            return_val = latest_distance;
            break;
        case dvr.setFilter(uint32_t rate, uint32_t samples):
            if ( samples && (MAX_SAMPLES >= samples) ) {
                filter = samples;
            }
            if ( 60 <= rate ) {
                speed = rate * 1000 * 100;
            }
            break;
        }
    }

}
