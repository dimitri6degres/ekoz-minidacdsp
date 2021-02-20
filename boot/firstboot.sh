#!/bin/sh
echo "install ekoz-minidacdsp"
echo "------------"


echo ">>>>> install files"
cp /boot/ekoz-minidacdsp.xml /home/pi/.
cp -R /boot/ekozGATT /home/pi/.


echo ">>>>> install hostname"
# sudo sed -i 's/raspberrypi/ekoz-minidacdsp/' /etc/hosts
# sudo sed -i 's/raspberrypi/ekoz-minidacdsp/' /etc/hostname
sudo raspi-config nonint do_hostname ekoz-minidacdsp
sudo hostnamectl set-hostname "ekoz-minidacdsp" --pretty



echo "install asound"
cat <<EOT >/etc/asound.conf
defaults.pcm.card 0
defaults.ctl.card 0

pcm.hifiberry {
  type hw
  card 0
  device 0
}
pcm.dmixer {
  type dmix
  ipc_key 1024
  ipc_perm 0666
  slave.pcm "hifiberry"
  slave {
    period_time 0
    period_size 1024
    buffer_size 8192
    rate 44100
    format S32_LE
  }
  bindings {
    0 0
    1 1
  }
}
ctl.dmixer {
  type hw
  card 0
}
pcm.softvol {
  type softvol
  slave.pcm "dmixer"
  control {
    name "Softvol"
    card 0
  }
  min_dB -90.2
  max_dB 0.0
}
pcm.!default {
  type plug
  slave.pcm "softvol"
}
EOT

# ALSA settings
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

# BlueALSA
mkdir -p /etc/systemd/system/bluealsa.service.d
cat <<'EOF' > /etc/systemd/system/bluealsa.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/bluealsa -i hci0 -p a2dp-sink
RestartSec=5
Restart=always
EOF

cat <<'EOF' > /etc/systemd/system/bluealsa-aplay.service
[Unit]
Description=BlueALSA aplay
Requires=bluealsa.service
After=bluealsa.service sound.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/bluealsa-aplay --pcm-buffer-time=250000 00:00:00:00:00:00
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF


cat <<'EOF' > /etc/systemd/system/bt-agent.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF


# Bluetooth udev script
cat <<'EOF' > /usr/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
    # disconnect wifi to prevent dropouts
    #ifconfig wlan0 down &
fi

if [ "$action" = "remove" ]; then
    # reenable wifi
    #ifconfig wlan0 up &
    #bluetoothctl discoverable on
fi
EOF
chmod 755 /usr/local/bin/bluetooth-udev

cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF


echo ">>>>> install BT config"
sudo sed -i 's/bluetoothd/bluetoothd -E/' /lib/systemd/system/bluetooth.service


cat <<'EOF' > /etc/systemd/system/ekoz-minidacdsp.service
[Unit]
Description=Ekoz-minidacdsp
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStart=/usr/bin/python3 /home/pi/ekozGATT/ekozGATT.py
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF



echo "------------"
echo ">>>>> make system lighter"

# Disable swapfile
dphys-swapfile swapoff
dphys-swapfile uninstall
systemctl disable dphys-swapfile.service

# Remove unwanted packages
apt-get remove -y --purge triggerhappy logrotate dphys-swapfile fake-hwclock
apt-get autoremove -y --purge
apt-get install -y busybox-syslogd
dpkg --purge rsyslog

# Disable apt activities
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily.timer
systemctl disable man-db.timer

# Move resolv.conf to /run
mv /etc/resolv.conf /run/resolvconf/resolv.conf
ln -s /run/resolvconf/resolv.conf /etc/resolv.conf

# Adjust kernel command line
# sed -i.backup -e 's/rootwait$/rootwait fsck.mode=skip noswap ro/' /boot/cmdline.txt

# Edit the file system table
# sed -i.backup -e 's/vfat\s*defaults\s/vfat defaults,ro/; s/ext4\s*defaults,noatime\s/ext4 defaults,noatime,ro/' /etc/fstab

# Make edits to fstab
# cat <<'EOF' >> /etc/fstab
# tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0
# tmpfs /var/tmp tmpfs mode=1777,nosuid,nodev 0 0
# tmpfs /var/spool tmpfs mode=0755,nosuid,nodev 0 0
# tmpfs /var/log tmpfs mode=0755,nosuid,nodev 0 0
# tmpfs /var/lib/dhcpcd5 tmpfs mode=0755,nosuid,nodev 0 0
# EOF


echo "------------"
echo ">>>>> install and update system"
sudo apt update
sudo apt upgrade -y


echo ">>>>> install python"
sudo apt-get install -y python3-pip libxslt1-dev libxml2-dev zlib1g-dev python3-lxml python-lxml libxml2-dev libxslt-dev python-dev  python3-dbus
sudo apt-get install -y --no-install-recommends alsa-base alsa-utils bluealsa bluez-tools

echo ">>>>> install dsptoolkit"
sudo pip3 install --upgrade hifiberrydsp
sudo pip3 install gpiozero


for i in sigmatcp; do
 sudo systemctl stop $i
 sudo systemctl disable $i
done

sudo mkdir -p /var/lib/hifiberry

LOC=`which dsptoolkit`
sudo mkdir ~/.dsptoolkit

# Create systemd config for the TCP server
LOC=`which sigmatcpserver`

cat <<EOT >/tmp/sigmatcp.service
[Unit]
Description=SigmaTCP Server for HiFiBerry DSP
Wants=network-online.target
After=network.target network-online.target
[Service]
Type=simple
ExecStart=$LOC --alsa
StandardOutput=journal
[Install]
WantedBy=multi-user.target
EOT

sudo mv /tmp/sigmatcp.service /lib/systemd/system/sigmatcp.service

cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
# DiscoverableTimeout = 1
# PairableTimeout = 1

[Policy]
AutoEnable=true
EOF


echo ">>>>> relaunch services"

systemctl daemon-reload
systemctl enable bluealsa-aplay
systemctl enable bt-agent.service
systemctl enable ekoz-minidacdsp.service

systemctl start sigmatcp.service 
systemctl enable sigmatcp.service 


echo ">>>>> install DSP profile"
dsptoolkit install-profile /home/pi/ekoz-minidacdsp.xml

sudo adduser pi bluetooth
sudo adduser pi lp
sudo hciconfig hci0 sspmode 1
sudo hciconfig hci0 piscan


cat <<'EOF' > /etc/rc.local
#!/bin/sh -e
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi
echo discoverable no | sudo bluetoothctl
echo pairable no | sudo bluetoothctl
/bin/sleep 1 && ifconfig wlan0 down
# sudo python3 /home/pi/ekozGATT/ekozGATT.py
exit 0
EOF

echo ">>>>> need to reboot"
sudo reboot