#Ultrasonic Range Finder Module for xCore

This repository provides an xCore drivermodule for the HC-SR04 ultrasonic sensor / range finder.  Also included is an example application that runs on the [XMOS xCore startKIT](http://www.xmos.com/startkit).

###Introduction
The HC-SR04 devices, often called ping sensors, use sonar to determine distance to an object.  The sensor has 4 connections:
- VCC Power +5 Volts.
- TRIG Trigger input.
- ECHO Data output.
- GND Power supply common.

The startKIT starts a sensor reading by first generating a narrow trigger pulse on an xCore output port.  This is connected to the sensor trigger input.  The driver uses a select statement to watch for events on the echo input port, measuring the width of the sensor output pulse.  This width is proportional to distance.  

Note that since the sensor is 5V and the startKIT is 3V, a level shifter is required between the ECHO signal and the kit.  A simple resistor divider was used.

###Calculation
Distance is determined based on the speed of sound:  distance = (ECHO pulse width * speed of sound) / 2.


