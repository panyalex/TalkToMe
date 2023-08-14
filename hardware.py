#!/usr/bin/env python3          
                                
import signal                   
import sys
import RPi.GPIO as GPIO
BUTTON_GPIO = 16
LED_GPIO = 20
last_LED_state = 0
def signal_handler(sig, frame):
    GPIO.cleanup()
    sys.exit(0)
def button_pressed_callback(channel):
    filewrite()
def fileread():
    global last_LED_state
    handle = open("gpiobutton.txt", "r")
    if(int(handle.read()) == 1):
        filewrite()
        last_LED_state = 1
    else:
        last_LED_state = 0
    handle.close()
    GPIO.output(LED_GPIO, last_LED_state)
def filewrite():
    global last_LED_state
    if(last_LED_state == 1):
        newhandle = open("gpiobutton.txt", "w")
        newhandle.write("2")
        newhandle.close()
    fileread()
def initprogram():
    global last_LED_state
    handle = open("gpiobutton.txt", "r")
    if(int(handle.read()) == 1):
        last_LED_state = 1
    else:
        last_LED_state = 0
    handle.close()
    GPIO.output(LED_GPIO, last_LED_state)
   
if __name__ == '__main__':
    GPIO.setmode(GPIO.BCM)
    
    GPIO.setup(BUTTON_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    GPIO.setup(LED_GPIO, GPIO.OUT)
    GPIO.add_event_detect(BUTTON_GPIO, GPIO.FALLING, 
            callback=button_pressed_callback, bouncetime=200)
    initprogram()
    signal.signal(signal.SIGINT, signal_handler)
    signal.pause()
