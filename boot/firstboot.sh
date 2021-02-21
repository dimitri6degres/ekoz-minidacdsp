#!/bin/sh
echo "install ekoz-minidacdsp"
echo "------------"

raspi-config nonint do_hostname ekoz-minidacdsp
hostnamectl set-hostname "ekoz-minidacdsp" --pretty

cp /boot/ekoz-minidacdsp.xml /home/pi/.
cp -R /boot/ekozGATT /home/pi/.

cp /boot/asound.conf /etc/.
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

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


mkdir -p /var/lib/hifiberry
mkdir ~/.dsptoolkit

sed -i 's/#Class = 0x000100/Class = 0x200414/' /etc/bluetooth/main.conf

adduser pi bluetooth
adduser pi lp
hciconfig hci0 piscan
hciconfig hci0 sspmode 1


apt-get update
apt-get install -y python3-pip libxslt1-dev libxml2-dev zlib1g-dev python3-lxml python-lxml libxml2-dev libxslt-dev python-dev  python3-dbus alsa-base alsa-utils bluealsa bluez-tools

pip3 install hifiberrydsp gpiozero

systemctl daemon-reload

systemctl enable bluealsa-aplay
systemctl enable bt-agent.service
systemctl enable ekoz-minidacdsp.service
systemctl enable sigmatcp.service 
systemctl start sigmatcp.service 

dsptoolkit install-profile /home/pi/ekoz-minidacdsp.xml
 
sudo reboot
