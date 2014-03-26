//---------------------------------------------------------
// Ping sensor driver header
// by teachop
//

#ifndef __PING_H__
#define __PING_H__

#include "strip_config.h"

#define MAX_SAMPLES 8

// 100MHz * 1000000uSec * 2x / 344000mmps
#define ECHO_TO_MM 581

// ping sensor driver interface
interface ping_if {

    // data sheet recommends rate >= 60 mSec
    // defaults to 1000mm, 60mSec, 1 sample, toss 2
    void setFilter(uint32_t max_distance, uint32_t rate, uint32_t samples, uint32_t toss);

    // get distance in millimeters
    uint32_t getDistance(void);
};

void ping_task(port trigger, port pulse, interface ping_if server dvr);


#endif // __PING_H__
