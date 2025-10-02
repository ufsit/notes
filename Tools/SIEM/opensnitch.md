# Setup

## Proxmox opensnitch setup instructions

1) Install OpenSnitch

```bash
yum install libnetfiler_queue
rpm --nosignature -i ./opensnitch.rpm
```

2) Configure event forwarding:

```bash
vi /etc/opensnitchd/default-config.json
```

Change the "Address" line value to {Server_IP}:50051

3) Restart OpenSnitch daemon

```bash
systemctl restart opensnitch
systemctl enable --now opensnitch
```

4) Test connection

On the CentOS server:
```bash
ping google.com
```

Check the UI server for a notification for ping from the CentOS machine IP.

## How to install OpenSnitch Daemon on Ubuntu/Debian Servers 🟠🔴 ("worker" machines, in our case)

1) Install the daemon

```bash
sudo apt isntall ./opensnitch.deb
```

2) Configure event forwarding

```bash
sudo vim /etc/opensnitchd/default-config.json
```

Change the "Address" value to {Server_IP}:50051

3) Restart the daemon

```bash
sudo systemctl restart opensnitch
sudo systemctl enable --now opensnitch
```

4) Test the connection

On the Ubuntu/Debian machine:
```bash
ping google.com
```

The UI server should now show a notification for ping from the server's IP.

## Install UI Server on Kali 🔵 (the "controller" machine)

1) Install OpenSnitch UI

```bash
sudo apt install ./opensnitch-ui.deb
```

2) Open listening port

```bash
opensnitch-ui --socket [::]:50051
```
