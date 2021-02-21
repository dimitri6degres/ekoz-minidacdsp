# ekoz-minidacdsp

I wanted a dac with a "night mode" preset.  
Movies' soundtrack are awfull : we don't anderstand dialogs, but fx are very loud…  
it's impossible to watch a movie without playing permanently with the remote !

---

i've got a good stereo system (don't want HC 5.1…)  
i'm watching movies on a projector with an appleTV.  
So what i need is a small DAC with an optical input and stereo RCA output.  
After some googling, i don't see anything that can resolve my problem.  
The only way i've found was the Hifiberry DAC+ DSP  
https://www.hifiberry.com/shop/boards/hifiberry-dac-dsp/  
so let's go…

---

<img src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_02.jpg"></img>
The design is simple :  
the Hifiberry DAC+ DSP on a RaspberryPi Zero in a 3D printed box.  
the functionnalities are reduced to :  
INPUT : bluetooth A2DP streaming & toslink  
OUTPUT : ananlog RCA & digital toslink  
DSP : 4 presets (Bypass + 3 levels of compression)  
APP : a companion app that communicate in bluetooth with the RPi to :  
select the DSP presets | change dac volume | activate BT pairing | activate Wifi | shutdown Rpi | reset DSP

---
The 3D enclosure
<img src="https://github.com/dimitri6degres/ekoz-minidacdsp/raw/main/images/ekoz-minidacdsp_03.jpg"></img>

