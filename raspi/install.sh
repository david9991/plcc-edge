#!/bin/sh

export DEBIAN_FRONTEND=noninteractive

MACADDR=$1
USER=$2

if [ $(whoami) != "root" ]; then
	echo "Please run as root"
	exit 1
fi

echo "Stopping existing services..."
systemctl stop plcc-edge.service
systemctl stop node-red.service

if [ -z $MACADDR ]; then
	echo "Please enter Mac Address of your wired ethernet device"
	exit 1
fi

if [ -z $USER ]; then
	echo "Please enter the username"
	exit 1
fi

echo "Installing Dependencies..."
apt update && apt install -y build-essential git curl && apt clean

echo "Installing Edge Controller..."
curl --location -o /usr/local/bin/edge https://github.com/david9991/plcc-edge/raw/main/raspi/edge
chmod +x /usr/local/bin/edge

echo "Installing Real-Time Kernel..."
curl --location -o /tmp/linux-image-5.4.83-rt46-raspi_5.4.83-1_arm64.deb https://github.com/david9991/plcc-edge/raw/main/raspi/linux-image-5.4.83-rt46-raspi_5.4.83-1_arm64.deb
dpkg -i /tmp/linux-image-5.4.83-rt46-raspi_5.4.83-1_arm64.deb

echo "Setting up EtherCAT Interface..."
cat <<EOF > /etc/udev/rules.d/70-persistent-net.rules
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${MACADDR}", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="ecat1"
EOF

echo "Installing Node-Red..."
curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered | sudo -u $USER bash -s -- -s -- --confirm-install --node18

echo "Setting up services..."
cat <<EOF > /etc/systemd/system/plcc-edge.service
[Unit]
Description=PLCC Edge service

[Service]
ExecStart=/usr/local/bin/edge --name RaspberryPi4B
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF
cat <<EOF > /etc/systemd/system/node-red.service
[Unit]
Description=Node Red

[Service]
User=${USER}
ExecStart=node-red-pi
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF
cat <<EOF > /etc/systemd/system/ecat-networking.service
[Unit]
Description=EtherCAT Networking

[Service]
ExecStart=ifconfig ecat1 up
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF

systemctl enable plcc-edge.service
systemctl enable node-red.service
systemctl enable ecat-networking.service
systemctl restart plcc-edge.service
systemctl restart node-red.service
systemctl restart ecat-networking.service

echo "Done!"
