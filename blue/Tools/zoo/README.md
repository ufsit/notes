# zoo (funmap by pyukey)
F is for friends that blue team together. <br>
One-stop shop for blue team management.

## Installation

Make sure you're in your home directory and run `git clone https://github.com/pyukey/funmap.git`

## Running

The toolkit is driven by an interactive launcher that fans commands and payloads
out to your hosts through the `meow` driver library.

```
cd zoo
./launcher.sh
```

Start with **[0] Setup Hosts (elephant)** — it collects admin creds + IPs, fingerprints
each host's OS (via hawk's nmap), and builds the host inventory (`USER IP PASSWORD OS DOMAIN`)
that every other module reads. Then **[1] Password Roll** rolls straight away. `[a]` runs an
ad-hoc command and `[b]` an ad-hoc script across every host; `[x]` exits.

## Windows hosts

meow talks to Windows hosts with [netexec](https://github.com/Pennyw0rth/NetExec)
(`nxc`) instead of ssh. One-time operator prep (with network, before competition):

```
 ./setup.sh          # installs netexec via your package manager; then snapshot your operator box
```

During **Password Roll**, elephant fingerprints each host's OS with hawk's nmap and
tags it `linux` or `windows` (you set a domain per Windows host, blank = local admin).
From then on every module targets each host with the right transport automatically;
modules without a Windows payload skip Windows hosts with a notice.

## Modules

Located in the `modules` subdirectory. These are the 'animals' of the zoo, each providing functionality to the manager.

- `armadillo` - General system hardening scripts.
- `beaver` - Fixes holes in the dam (bad service files, missing binaries, etc.) and performs the appropriate action to restore the green check
- `chipmunk` - Anything we need for backups, including creating, restoring, managing, and hosting backups.
- `chomp` - Host-based EDR. The module is responsible for deploying, starting it, collecting its logs, and health checks.
- `elephant` - Password manager.
- `elk` - Automation scripts for deploying the Elastic Search stack.
- `hawk` - Initial scans of the network to populate the network diagram of zoo.
- `lynx` - PAM debugger, analyzes bad PAM configs and backdoors.
- `meerkat` - Generic service health checks (whatever `woodpecker` doesn't cover).
- `meow` - The "Connector" module, responsible for establishing connections with targets and passing payloads through. Many modules will require `meow` for connecting.
- `nematode` - Gain visibility into service running on hosts and maps relationships between services (i.e. a web server has its database on a different host).
- `phoenix` - Automated firewall tasks.
- `suricata` - Automated suricata deployment. Automated connection to ELK.
- `turtle` - Caddy WAF deployment
- `woodpecker` - Continuously runs login attempts to check for default credentials.
- `woof` - Interactive script that patches system and service misconfigurations, can run on a schedule.

## Deprecated: funmap web UI

The original `funmap.sh` scanner and its browser-based network diagram have been
retired to the `deprecated/` folder while the module/launcher architecture takes
over. They are kept for reference and are no longer part of the supported flow.

The old flow was: `sudo ./funmap.sh` (enter users, passwords, and subnets), then
serve the generated diagram with `python3 -m http.server` from the project directory.

![image info](./assets/Ex1.png)
![image info](./assets/Ex2.png)

The web UI supported a fully customizable network diagram, a password manager view,
a default-credential brute forcer, and per-node deploy/patch buttons. That
functionality now lives in the individual modules above, driven from `launcher.sh`.
