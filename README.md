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
• install the app on your phone  
• mount the hifiberry DAC+ DSP module on top of the raspberry pi zero  
• download the <a href=https://github.com/dimitri6degres/ekoz-minidacdsp/archive/main.zip>zip file from this repo</a>  
• download the last os image from <a href=https://github.com/nmcclain/raspberian-firstboot/releases>raspberian-firstboot</a>  
• mount the image on your computer then copy files from this boot folder to the image boot volume  
• unmout boot folder and copy the os image on the sdcard (i.g. <a href=https://www.balena.io/etcher/>balenaEtcher</a>)  
• mount the card in the raspberry and boot it  
• open the app on your phone, wait for the dac to be detected  
• enter your wifi credentials and validate  
• wait a quite long time for the raspberry to install everything (20min?)  
• the raspberry must reboot by itself to finish the install
• your app must tell you when it's ok !

## how it works

-- DSP on hifiberry card  
the dsp is programmed with <a href=https://www.analog.com/en/design-center/evaluation-hardware-and-software/software/ss_sigst_02.html#>sigmastudio</a> to have 4 presets (1 bypass, 3 levels of compression)  
the project file (<a href=https://github.com/dimitri6degres/ekoz-minidacdsp/tree/main/sources/sigmastudio>ekoz-minidacdsp.dspproj</a>) structure is made from 4 "shells" that can be modified  
(looking for acoustics pros to improve settings)  
There is no detection or switch for inputs, raspberry and toslink signals overlap  
the xml profile file is tagged with registers for the volume and the channel's switch  

-- services on Raspberry  
in normal mode, wifi is disabled, bluetooth enabled but not discoverable nor pairable.  
a GATT server is launched with a python script to communicate between the phone's app and the dsp.  
the script uses the registers to read and modify on the fly the values in the dsp.
BlueAlsa is used to stream bluetooth A2DP music.

## Projects that help me…
I'm not a code developper or expert with rapsberry, dsp, python…  
but google and github is a perfect source of inspiration, so thanks to:  
<a href=https://stackoverflow.com>Stackoverflow.com, this wealth of information</a>  
<a href=https://www.hifiberry.com/modify-dsp-registers-on-the-fly/>the hifiberry forum, guides and github</a>  
<a href=https://github.com/Douglas6/cputemp>douglas6 / cputemp</a>  
<a href=https://github.com/nicokaiser/rpi-audio-receiver>nicokaiser / rpi-audio-receiver</a>  
<a href=https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor>RayWenderlich.com</a>  
and others…

## But I need some more help
This project is not finished. I just drew the outlines.  
What i did is just DIY, even if it doesn't work too badly...  
But i need now anyone who has python knowledge to re-write the python script,  
a raspberry/linux expert to rewrite the install script,  
a swift coder to improve the ios app,  
a android coder to make it available for all,
maybe a web coder to make a web version
