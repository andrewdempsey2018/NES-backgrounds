# NES input

Use the up / down / left / right buttons on the NES controller to move the ship around on screen

![screenshot](scrshot.png)

## How to assemble

Step 1: Assemble asm file into an object file

**ca65 bg.asm -o bg.o -t nes**

Step 2: link the object file to the nes target (yields a .NES rom for use with emulator, tested on Fceux)

**ld65 bg.o -o bg.nes -t nes**

# Info

# Links

## FCEUX:

Emulator used for testing

https://fceux.com/web/home.html

## CC65 (CA65)

Assembler used

https://www.cc65.org/

## More info

See Nerdy Nights tutorial

https://nerdy-nights.nes.science/#main_tutorial-5