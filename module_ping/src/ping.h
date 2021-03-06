//---------------------------------------------------------
// Ping sensor driver header
// by teachop
//

#ifndef __PING_H__
#define __PING_H__

#define MAX_SAMPLES 8
#define MIN_RATE 10

// 100MHz * 1000000uSec * 2x / 344000mmps
#define ECHO_TO_MM 581

// ping sensor driver interface
interface ping_if {

    // data sheet recommends rate >= 60 mSec
    // defaults to 3000mm, 60mSec, 1 sample, toss 2 on lost echo
    void setFilter(uint32_t max_distance, uint32_t rate, uint32_t samples, uint32_t toss);

    // get distance in millimeters
    uint32_t getDistance(void);
};

// while ping satisfies combinable requirements
// be aware stable pulse measurement is time sensitive
[[combinable]]
void ping_task(port trigger, port pulse, interface ping_if server dvr);


#endif // __PING_H__
