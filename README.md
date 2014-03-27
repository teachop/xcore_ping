##Ultrasonic Distance Sensing for xCore
This repository provides an xCore driver module for the HC-SR04 ultrasonic sensor / range finder.  An example app is included that uses an [XMOS xCore startKIT](http://www.xmos.com/startkit) with this sensor to make a [NeoPixel LED strip](https://github.com/teachop/xcore_neopixel_buffered) interactive.

###Introduction
The [HC-SR04](http://www.micropik.com/PDF/HCSR04.pdf) devices, often called ping sensors, use sonar to determine distance to an object.

The sensor has 4 connections:
- **VCC**, Power supply input, +5 Volts.
- **Trig**, Trigger input, 10 microsecond high-going pulse.
- **Echo**, Data output, high pulse with width representing distance.
- **GND**, Power supply common.

**Note:** The sensor is 5V and the XCore part on the startKIT not 5V tolerant.  A voltage divider was used between the **Echo** signal and the input port to avoid damage to the CPU from over-voltage.

The startKIT begins a sensor reading by first generating a narrow trigger pulse on an xCore output port.  This is connected to the sensor trigger input.  Ultrasonic pulses are then produced by the sensor to determine distance to an obstacle - something within range that causes the ultrasound ping to bounce back.  This bounce time is signaled by controlling the Echo output pulse width.  The xCore measures this width to determine the distance.

###Driver API
The driver source is organized as an xCore module.  It uses the the xC interface mechanism for task communication, which provides the API.
- **getDistance()**, Get optionally filtered distance reading in millimeters.
- **setFilter(range, rate, samples, toss)**, Optionally adjust the driver filter settings.

Filter parameters:
- **range** - in millimeters, the maximum distance to accept as valid.  Default 3000.
- **rate** - in milliseconds, the sample rate, >= 10.  Default 60.
- **samples** - the number of samples to average, between 1 and 8.  Default 1.
- **toss** - the number of samples to discard when recovering from a bad reading.  Must be > 0.  Default 2.

The driver task runs concurrently, using a select statement to watch for events.  These events come from the API interface, a sample rate timer, and input port transitions from the **Echo** signal.  The main task of the driver is to measure the width of the sensor output pulse.  Readings are taken continually at the requested sample rate.

###Measurement
Distance is determined based on the speed of sound:  distance = (**Echo** pulse width * speed of sound) / 2.  Timing on the xCore is microseconds*100 resolution (100MHz) giving a formula:
- Millimeters = width / 581

The driver uses logic to reject the crazy values and provide filtering.  The sensor data sheet recommends that readings be taken at intervals >= 60 milliseconds to avoid unwanted echo signals.  The optional filtering (which defaults to off) is an average of the most recent in-range samples.  If a value is out of range, it is replaced in the calculation by the prior valid raw reading.  Filter setting is adjusted by the driver API **setFilter()**.

