<img height=350px src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_01.png"></img>

## the prelude 

I wanted a dac with a "night mode" preset.  
Movies' soundtrack are awfull : we don't anderstand dialogs, but fx are very loud…  
it's impossible to watch a movie without playing permanently with the remote !


i've got a good stereo system (don't want HC 5.1…)  
i'm watching movies on a projector with an appleTV.  
So what i need is a small DAC with an optical input and stereo RCA output.  
After some googling, i don't see anything that can resolve my problem.  
The only way i've found was the <a href=https://www.hifiberry.com/shop/boards/hifiberry-dac-dsp>Hifiberry DAC+ DSP </a>  
so let's go…


## the design
<img src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_02.jpg"></img>  
The design is simple :  
the Hifiberry DAC+ DSP on a RaspberryPi Zero in a 3D printed box.  
the functionnalities are reduced to :  
INPUT : bluetooth A2DP streaming & toslink  
OUTPUT : ananlog RCA & digital toslink  
DSP : 4 presets (1 bypass + 3 levels of compression)  
APP : a companion app that communicate in bluetooth with the RPi to :  
select the DSP presets | change dac volume | activate BT pairing | activate Wifi | shutdown Rpi | reset DSP


## The 3D enclosure
In this design, the cards are plugged in rather than screwed.  
Everything is held by a single screw.  
the box is presented verticaly.
Cooling is provided by long slits.  
There is an empty space in the base to fit an SDcard adapter.

<img src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_03.jpg"></img>

STL files :  
<a href=https://github.com/dimitri6degres/ekoz-minidacdsp/blob/main/sources/3D_enclosure/ekoz-minidacdsp_base.stl>ekoz-minidacdsp_base.stl</a> | <a href=https://github.com/dimitri6degres/ekoz-minidacdsp/blob/main/sources/3D_enclosure/ekoz-minidacdsp_hood.stl>ekoz-minidacdsp_hood.stl</a> | <a href=https://github.com/dimitri6degres/ekoz-minidacdsp/blob/main/sources/3D_enclosure/ekoz-minidacdsp_strip.stl>ekoz-minidacdsp_strip.stl</a>


## the companion app
The interface is intentionally simplistic. 
<img src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_04.jpg"></img>   
It is currently only done for iphones...  
(looking for someone to make it available for androïd…)

## Installation
• mount the hifiberry DAC+ DSP module on top of the raspberry pi zero  
• install the os image on the sdcard (i.g. <a href=https://www.balena.io/etcher/>balenaEtcher</a>  
• mount the card in the raspberry and boot it.  

