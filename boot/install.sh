#!/bin/sh
echo "install ekoz-minidacdsp"
echo "------------"

echo "install some files"
# install files from boot folder
cp /boot/ekoz-minidacdsp.xml /home/pi/.
cp -R /boot/ekozGATT /home/pi/.
cp /boot/asound.conf /etc/.


echo "update system"
sudo apt update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
sudo apt upgrade -y

echo "install packets"
sudo apt install -y python3-pip libxslt1-dev libxml2-dev zlib1g-dev python3-lxml python-lxml libxml2-dev libxslt-dev python-dev  python3-dbus alsa-base alsa-utils bluealsa bluez-tools


# config for bluetooth audio
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf


echo "install services"
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

sed -i 's/bluetoothd/bluetoothd -E/' /lib/systemd/system/bluetooth.service


# config GATT server service

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

cat <<'EOF' > /lib/systemd/system/sigmatcp.service
[Unit]
Description=SigmaTCP Server for HiFiBerry DSP
Wants=network-online.target
After=network.target network-online.target
[Service]
Type=simple
ExecStart=/usr/local/bin/sigmatcpserver --alsa
StandardOutput=journal
[Install]
WantedBy=multi-user.target
EOF



# config tools for DSP

mkdir -p /var/lib/hifiberry
mkdir ~/.dsptoolkit



echo "install hifiberry toolkit"
sudo pip3 install hifiberrydsp gpiozero

echo "make sysstem lighter"
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


# more bluetooth config 

echo "enable services"

sed -i 's/#Class = 0x000100/Class = 0x200414/' /etc/bluetooth/main.conf
adduser pi bluetooth
adduser pi lp
hciconfig hci0 piscan
hciconfig hci0 sspmode 1


# reload services

systemctl daemon-reload

systemctl enable bluealsa-aplay
systemctl enable bt-agent.service
systemctl enable ekoz-minidacdsp.service
systemctl enable sigmatcp.service 
systemctl start sigmatcp.service 

#  wait for sigmatcp service to start
while true; do
    if [ $(systemctl is-active sigmatcp.service) == "active" ]; then
        break
    fi

    sleep 1
done

echo "install dsp profile"
dsptoolkit install-profile /home/pi/ekoz-minidacdsp.xml
 
 
cat <<'EOF' > /etc/rc.local
#!/bin/sh -e
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf "My IP address is %s\n" "$_IP"
fi
#/bin/sleep 1 && ifconfig wlan0 down
exit 0
EOF

raspi-config nonint do_hostname ekoz-minidacdsp
hostnamectl set-hostname "ekoz-minidacdsp" --pretty



echo "make system read-only"

# Adjust kernel command line
sed -i.backup -e 's/rootwait$/rootwait fsck.mode=skip noswap ro/' /boot/cmdline.txt

# Edit the file system table
sed -i.backup -e 's/vfat\s*defaults\s/vfat defaults,ro/; s/ext4\s*defaults,noatime\s/ext4 defaults,noatime,ro/' /etc/fstab

# Make edits to fstab
cat <<'EOF' >> /etc/fstab
tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0
tmpfs /var/tmp tmpfs mode=1777,nosuid,nodev 0 0
tmpfs /var/spool tmpfs mode=0755,nosuid,nodev 0 0
tmpfs /var/log tmpfs mode=0755,nosuid,nodev 0 0
tmpfs /var/lib/dhcpcd5 tmpfs mode=0755,nosuid,nodev 0 0
EOF


echo "install complete, you can reboot now!"
