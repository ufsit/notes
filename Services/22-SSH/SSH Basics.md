# SSH
SSH can be seen as a secure tunnel between two parties to transmit information. The SSH protocol was created for two different parties that can be in the same local network, or even across the world as a way to login into another person's computer. It was also meant to be secure even on unsecure networks or public networks that everyone can access.

## Asymmetric Encryption:
Very similar to PGP (Pretty Good Privacy) as it generates two keys: one public key, and one private key. These keys are mathematically  generated to be nearly impossible to crack(unless you have some quantum computer). Generally, you would send people you want to receive information from a public key, they would use that key to encrypt whatever data. Afterwards, you would utilize your private key to decrypt those pieces of data/information. 

## SSH steps
Generally when you initiate a SSH connection, it will follow these steps:
1. Establish a connection using TCP/UDP packets (or using something like websockets) 
2. Establish the packet length. (4 bytes)
3. Establish Padding Amount (1 byte)
4. The Payload/Data you want (Size varies)
5. Padding; this will just have random bytes that would be combined with the payload to make the whole thing encrypted. This is so anyone sniffing on the network/connection have a harder time telling what is going on.
6. Message Authentication Code/Tag; think of it as a receipt that everything in this process went smoothly and it wasn't tampered with.
7. Usually this entire process would also be compressed in order for there to be more data sent over from different networks at a time without using more bandwidth.
8. This is all for just one packet, this process will only continue to repeat for several other packets.

Any MiTM attack reading SSH connections can only read the Packet Length and the Message Authentication Code in this entire instruction list.

# Protocol versus Implementation
It's important to differentiate what a protocol does versus what an implementation would do. A protocol is generally an universal set of rules or laws that computer theorists would create for any number of specific tasks. An implementation is the actual code/program itself where the programmer would do their best to abide by those set of rules with some small differences. It's best to think the protocol as the Uno's set of rules, with the game you actually play together with your friends being the implementation of those rules.  

### How does this relate to SSH?
It relates because SSH itself is the protocol, not an actual program. As a result, there exists many implementations of SSH and each slightly vary on how they follow the SSH protocol itself. A popular implementation of SSH is called OpenSSH. 

# Creating an OpenSSH server
1. on your terminal, run `sudo apt install openssh-server` if it is not installed already.
2. to modify the config of your SSH server, you can go to this dir: 
`/etc/ssh/sshd_config` and using your favorite text editor, you can modify these values to until your heart's content. 
3. To know what actual permissions/configurations you can change on that `sshd_config` file, you should run `man sshd_config.` It will explain the format and each configuration in detail.
4. Generally the main modifications you will make on `sshd_config` will be anything with Authentication in the naming since that is how the OpenSSH server will handle any legit or malicious user trying to enter that port. Another one would be anything with X11 before it, since it references your display system and if any GUI is allowed, it can allow for hackers to find easier exploits to bypass the OpenSSH authentication. Lastly, another one you should always check is PermitRootLogin, since this could allow whether the root user is allowed to remotely log in via SSH. Any option besides `yes` is advised.


## Why should I care about OpenSSH?

Any OpenSSH server running on an open port will be what is considered an attack vector. Malicious actors will tend to target any OpenSSH port that may be open in order to breach your system and take control over that computer.

// w.i.p

# Sensitive settings
* SSH is already a very secure protocol, it really earns the S in SSH. 
* Typicaly hardening/settings to watch our for is the `PermitRootLogin no` setting in `/etc/ssh/sshd_config`.
* An additional step would be not use passwords and use public/private keys, but this has never been used in competition <br><br>

# SCP 
* Secure Copy (SCP) uses an SSH tunnel to securely transfer a file from one host to another
* `scp [SOURCE_FILE(S)] [REMOTE_USER]@[REMOTE_IP_ADDRESS]:[DESTINATION_ADDRESS]`