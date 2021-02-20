#!/usr/bin/python3

"""Copyright (c) 2021, Dimitri Fontaine

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import dbus
import sys
import subprocess
import os
import fileinput
import time
import xml.etree.ElementTree as ET

from threading import Timer
from advertisement import Advertisement
from service import Application, Service, Characteristic, Descriptor
from gpiozero import CPUTemperature

GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1"

GATT_CHRC_IFACE2 = "org.bluez.GattCharacteristic1"
NOTIFY_TIMEOUT = 5000

SERVER_VERSION = "V1.03"

class EkozminidacdspAdvertisement(Advertisement):
    def __init__(self, index):
        Advertisement.__init__(self, index, "peripheral")
        self.add_local_name("ekoz-minidacdsp")
        self.include_tx_power = True



# register-service 7ba6d936-6deb-11eb-9439-0242ac130002
 
        
        
class EkozminidacdspService(Service):
    EKOZMINIDACDSP_SVC_UUID = "00000001-6deb-11eb-9439-0242ac130002"

    def __init__(self, index):

        self.wifi = True
        self.bluetooth = False
        
        root = ET.parse('/var/lib/hifiberry/dspprogram.xml')
        for temp in root.findall('.//metadata'):
                if temp.get("type") == "channelSelectRegister":
                    print(temp)
                    self.channelRegHex = hex(int(temp.text))
                elif temp.get("type") == "volumeControlRegister":
                    print(temp)
                    self.volumeRegHex = hex(int(temp.text))
        
        self.volume = self.read_volume()
        self.channel = self.read_channel()

        Service.__init__(self, index, self.EKOZMINIDACDSP_SVC_UUID, True)
        
        self.add_characteristic(SystemCharacteristic(self))
        self.add_characteristic(WifiCharacteristic(self))
        self.add_characteristic(DSPCharacteristic(self))

        print("init service ok")

        
    def read_channel(self):
        bashCmd = ["dsptoolkit", "read-int", self.channelRegHex]
        process = subprocess.Popen(bashCmd, stdout=subprocess.PIPE)
        output, error = process.communicate()
        output = output.rstrip().decode("utf-8")

        channel = int(output)

        return str(int(channel))

    def read_volume(self):
        bashCmd = ["dsptoolkit", "read-int", self.volumeRegHex]
        process = subprocess.Popen(bashCmd, stdout=subprocess.PIPE)
        output, error = process.communicate()
        output = output.rstrip().decode("utf-8")

        volume = int(output)
        volume = ((volume - 1677722) * 100) / 15099494

        return str(int(volume))




    def is_wifi_up(self):
    
        f = open('/sys/class/net/wlan0/operstate', 'r')
        text = f.readline().rstrip()
        f.close()
        output = False
        if str(text)[0] == 'u':
            output = True
        return output

    def is_bluetooth_up(self):
    
        f = open('/sys/class/net/wlan0/operstate', 'r')
        text = f.readline().rstrip()
        f.close()
        output = False
        if str(text)[0] == 'u':
            output = True
        return output

    def set_new_password(self, credential):
       
        os.system('ifconfig wlan0 down')
     
        print("WifiPass")

        
        f = open('/etc/wpa_supplicant/wpa_supplicant.conf', 'r')
        in_file = f.readlines()
        print(in_file)
        f.close()

        newcredential = credential.split("&&&")
        print(newcredential[0][1:])
        print(newcredential[1])
        print(newcredential[2])
        
        out_file = []
        for line in in_file:
            print(line)
            if line.startswith("country"):
                    line = 'country='+newcredential[0][1:]+'\n'
            if line.startswith("     ssid"):
                    line = '     ssid='+'"'+newcredential[1]+'"'+'\n'
            if line.startswith("     psk"):
                    line = '     psk='+'"'+newcredential[2]+'"'+'\n'
            out_file.append(line)
            
        f = open('/etc/wpa_supplicant/wpa_supplicant.conf', 'w')
        for line in out_file:
            f.write(line)
        f.close()

        os.system('ifconfig wlan0 up')
 
 
        

        
        
class SystemCharacteristic(Characteristic):
    SYS_CHARACTERISTIC_UUID = "00000002-6deb-11eb-9439-0242ac130002"

    def __init__(self, service):
        Characteristic.__init__(
                self, self.SYS_CHARACTERISTIC_UUID,
                ["notify", "write-without-response"], service)
        self.notifying = False
        print("init system ok")
        
        
    def WriteValue(self, value, options):
        val = str(value[0]).upper()
        if val == "1":
            os.system('sudo shutdown -r now')
        elif val == "2":
            os.system('sudo halt')
            
    def get_temperature(self):
        value = []

        cpu = CPUTemperature()
        temp = cpu.temperature

#        print(temp)
        strtemp = str(round(temp, 1))
        for c in strtemp:
            value.append(dbus.Byte(c.encode()))

        return value

    def set_temperature_callback(self):
        if self.notifying:
            value = self.get_temperature()
            self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])

        return self.notifying

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return
        self.notifying = True

        value = []
        desc = SERVER_VERSION
        for c in desc:
            value.append(dbus.Byte(c.encode()))
        self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])
        self.add_timeout(NOTIFY_TIMEOUT, self.set_temperature_callback)

    def StopNotify(self):
        self.notifying = False
            

        
 

class WifiCharacteristic(Characteristic):
    WIFI_CHARACTERISTIC_UUID = "00000003-6deb-11eb-9439-0242ac130002"

    def __init__(self, service):
        
        Characteristic.__init__(
                self, self.WIFI_CHARACTERISTIC_UUID,
                ["write-without-response", "notify", "read"], service)
        self.notifying = False
        print("init wifi ok")

    def get_wifistatus(self):
        valwifi = "W0"
        if self.service.is_wifi_up():
            valwifi = "W1"
        valblue = "B0"
        if self.service.bluetooth:
            valblue = "B1"
        value = []
        for c in str(valwifi + valblue):
            value.append(dbus.Byte(c.encode()))

        return value


    def set_temperature_callback(self):
        if self.notifying:
            value = self.get_wifistatus()
            self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])

        return self.notifying

    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return
        self.notifying = True
        self.add_timeout(10000, self.set_temperature_callback)
        
    def StopNotify(self):
        self.notifying = False
        

    def ReadValue(self, options):

        value = self.get_wifistatus()
        return value

    def bluetoothNo(self):
        cmd = 'echo discoverable no | sudo  bluetoothctl && echo pairable no | sudo  bluetoothctl'
        os.system(cmd)
        print("make bluetooth pairable no")
        self.service.bluetooth = False


    def bluetoothYes(self):
        cmd = 'echo discoverable yes | sudo  bluetoothctl && echo pairable yes | sudo  bluetoothctl'
        os.system(cmd)
        print("make bluetooth pairable yes")
        self.service.bluetooth = True
        t = Timer(60, self.bluetoothNo)
        t.start()


    def WriteValue(self, value, options):
        val = str(value[0]).upper()
        if val.startswith("W"):
            print("wifi toggle")
            if self.service.wifi == True:
                print("shut down wifi")
                cmd = 'ifconfig wlan0 down'
                os.system(cmd)
                self.service.wifi = False
            else:
                print("power up wifi")
                cmd = 'ifconfig wlan0 up'
                os.system(cmd)
                self.service.wifi = True
        elif val.startswith("B"):
            print("bluetooth toggle")
            if self.service.bluetooth == True:
                self.bluetoothNo()
            else:
                self.bluetoothYes()
        elif val.startswith("R"):
            print("bluetooth reseting")
            cmd = 'for device in $(bt-device -l | grep -o "[[:xdigit:]:]\{11,17\}"); do echo "removing bluetooth device: $device | $(bt-device -r $device)"; done'
            os.system(cmd)
            self.bluetoothYes()
            print("bluetooth reseted")
        else:
            print("wifi" + str(bytearray(value).decode()))
            self.service.set_new_password(str(bytearray(value).decode()))
            value = self.get_wifistatus()
            self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])
            self.notify()
         

        




        
        
class DSPCharacteristic(Characteristic):
    DSP_CHARACTERISTIC_UUID = "00000004-6deb-11eb-9439-0242ac130002"

    def __init__(self, service):
        
        Characteristic.__init__(
                self, self.DSP_CHARACTERISTIC_UUID,
                ["notify", "write-without-response", "read"], service)
        self.notifying = False
        print("init dsp ok")
        
        
    def get_volume_and_channel(self):
        string = self.service.channel + "V" + self.service.volume
        print(string)
        value = []
        for c in string:
            value.append(dbus.Byte(c.encode()))
        return value


    def StartNotify(self):
        if self.notifying:
            print('Already notifying, nothing to do')
            return
        self.notifying = True

    def dspNotify(self):
        self.notifying = False
        
        value = self.get_volume_and_channel()
        self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])
        self.StartNotify()
        print("notif")
        
    def StopNotify(self):
        self.notifying = False
        
        
    def WriteValue(self, value, options):
        val = str(bytearray(value).decode())
        
        if val.startswith("R"):
        
            bashCmd = ["dsptoolkit", "reset"]
            process = subprocess.Popen(bashCmd, stdout=subprocess.PIPE)
            output, error = process.communicate()
            self.service.volume = self.service.read_volume()
            self.service.channel = self.service.read_channel()
            print("reset ok")
            string = self.service.channel + "V" + self.service.volume
            print(string)
            self.dspNotify()


        elif val.startswith("C"):
        
            channel = str(val[1:])
            bashCmd = ["dsptoolkit", "write-mem", self.service.channelRegHex, channel]
            process = subprocess.Popen(bashCmd, stdout=subprocess.PIPE)
            output, error = process.communicate()
            self.service.channel = channel
            print("channel ok : " + channel)
            self.dspNotify()
            
            
        elif val.startswith("V"):
        
            volume = str(val[1:])
            volume2 = str( int( (15099494 * int(volume)) / 100 ) + 1677722 )
            if int(volume2) > 16777216 : volume2 = str(16777216)
            if int(volume2) < 1677722 : volume2 = str(1677722)
            
            bashCmd = ["dsptoolkit", "write-mem", self.service.volumeRegHex, volume2]
            process = subprocess.Popen(bashCmd, stdout=subprocess.PIPE)
            output, error = process.communicate()
            self.service.volume = volume
            print("volume ok : " + volume)
            self.dspNotify()
            
    def ReadValue(self, options):
        value = self.get_volume_and_channel()
        print("read")
        return value
        
        
        

#class DSPDescriptor(Descriptor):
#    DSP_DESCRIPTOR_UUID = "2903"
#    DSP_DESCRIPTOR_VALUE = "DSP system"
#
#    def __init__(self, characteristic):
#        Descriptor.__init__(
#                self, self.DSP_DESCRIPTOR_UUID,
#                ["read"],
#                characteristic)
#
#    def ReadValue(self, options):
#        value = []
#        desc = self.DSP_DESCRIPTOR_VALUE
#
#        for c in desc:
#            value.append(dbus.Byte(c.encode()))
#
#        return value
        
        
        
        

app = Application()
app.add_service(EkozminidacdspService(0))
app.register()

adv = EkozminidacdspAdvertisement(0)
adv.register()


try:
    app.run()
except KeyboardInterrupt:
    app.quit()
