# Initial Access

There are 2 ways you can practice:

1. Connect to the [practice network](#practice-network)
2. Run the malicious [setup script](#local-setup) in a VM

## Practice Network

Here is how you connect to the practice network:

1. Make sure you are connected to **eduroam**
2. Download the `UFSIT_BlueNet.ovpn`
3. Make sure you have OpenVPN installed (`sudo apt install openvpn` for Linux, and [here](https://openvpn.net/community/) for Windows)
4. For Linux, run `sudo openvpn UFSIT_BlueNet.ovpn` and you should see the message `Initialization Sequence Completed` if it is successful. If you run `ip a`, you will now see a `tun0` interface, which shows your ip for the OpenVPN network.    
For Windows, use the client you installed.

## Local Setup

1. `git clone https://github.com/pyukey/BlueDaBaDee.git`
2. `cd BlueDaBaDee/Linux/preplants`
3. `sudo ./plant.sh`
4. `exit` and then connect in a new terminal

# Nmap

Now that we are connected, we now need to get a *shell* on the individual machines. If you're blue-teaming, you will be given the IP, username and password. To connect, run `ssh <username>@<ip>` and then enter your password when prompted.

- **Note:** for these notes, whenever I include a variable in `<>`, that means it is a template you are supposed to fill in. For example, the above commmand would be `bob@172.168.1.10` if your username was `bob` and target IP was `172.168.1.10`. 
- **Note:** don't be alarmed if you don't see anything when you type in your password - this is a security measure. If you ever mess up when typing the password, just hold `Backspace` for a few seconds and then try again.

However, if we're red team, we won't be given this information so easily. Instead, we need to find it ourselves by *scanning* the network. To do this, we use the famous tool **nmap**.

1. Do an initial ping sweep on the subnet to see which hosts are up.
   
   - The simple method: `nmap -sn <subnet>`  
   Note: Windows machines may not respond to the ICMP ping.
   - The optimized method: `nmap -PR -PE -PP -PM -PO2 -PS21,22,23,25,80,110,113,135,137,143,443,445,691,993,995,1433,1521,2483,2484,3306,8008,8080,8443,7680,31339 -PA80,113,443,10042 -sn <subnet>`

2. Do a thorough scan on those IPs to see what ports are open.
   
   - The simple method: `nmap <ip>`
   - The optimized method: `nmap -sS -sV`, will also tell you the version of the services. 

3. Reference [hacktricks](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ssh.html) to see what services are typically open, what vulnerabilities they usually have, and how you can exploit them to get a shell.