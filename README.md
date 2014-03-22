##Ultrasonic Distance Sensing for xCore
This repository provides an xCore driver module for the HC-SR04 ultrasonic sensor / range finder.  Also included is an example application that runs on the [XMOS xCore startKIT](http://www.xmos.com/startkit).

###Introduction
The [HC-SR04](http://www.micropik.com/PDF/HCSR04.pdf) devices, often called ping sensors, use sonar to determine distance to an object.  The sensor has 4 connections:
- VCC, Power supply input, +5 Volts.
- Trig, Trigger input, 10 microsecond high-going pulse.
- Echo, Data output, high pulse with width representing distance.
- GND, Power supply common.

The startKIT begins a sensor reading by first generating a narrow trigger pulse on an xCore output port.  This is connected to the sensor trigger input.  Ultrasonic pulses are then produced by the sensor to determine distance to an obstacle - something within range that causes the ultrasound ping to bounce back.  This bounce time is signaled by controlling the Echo output pulse width.  The xCore measures this width to determine the distance.

**Note:** As the sensor is 5V and the startKIT is 3V, a level shifter is required between the ECHO signal and the kit to avoid damage to the CPU from over-voltage.  A simple resistor divider was used.  For the trigger signal no level shifting was required.

###Driver API
The driver source is organized as an xCore module.  It uses the the xC interface mechanism for task communication, which provides the API.
- getDistance(), Provide most recent distance information in millimeters.
- setFilter(range, rate, samples), Adjust the driver filtering (and resulting lag).

The driver task runs concurrently, using a select statement to watch for events.  These events come from the API interface, a sample rate timer, and input port transitions from the Echo signal.  The main task of the driver is to measure the width of the sensor output pulse.  

###Measurement
Distance is determined based on the speed of sound:  distance = (Echo pulse width * speed of sound) / 2.  Timing on the xCore is microseconds*100 resolution (100MHz clock) giving a formula:
- Millimeters = width / 580
The driver uses logic to reject the crazy values and provide a little filtering.  The sensor data sheet recommends that readings be taken at intervals > 60 milliseconds, so filtering options are rather limited!  This is adjusted by the driver API setFilter().

