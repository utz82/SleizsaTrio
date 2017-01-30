#!/bin/bash

./xm2sleizsatrio
dasm main.asm -f3 -v1 -otest.bin #-slbls.sym
mame channelf -rompath roms/ -cart test.bin -wavwrite song.wav