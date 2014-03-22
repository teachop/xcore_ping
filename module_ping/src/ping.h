//---------------------------------------------------------
// Ping sensor driver header
// by teachop
//

#ifndef __PING_H__
#define __PING_H__

#include "strip_config.h"

#define MAX_SAMPLES 10

// ping sensor driver interface
interface ping_if {
    void setFilter(uint32_t max_distance, uint32_t rate, uint32_t samples);
    uint32_t getDistance(void); //millimeters
};

void ping_task(port trigger, port pulse, interface ping_if server dvr);


#endif // __PING_H__
