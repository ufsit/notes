#~/.local/state/nvim/swap//%cyber%blueteam_fall22%cyberforce%THM_notes_sysinternals.md.swp Discuss Sysinternals

* Sysinternals
    - Back in 2006 Microsoft bought the company that made Sysinternals
    - **This was hueg news. These tools were really good and had advanced utilities for advanced users/sysadmins**

* Cool sidenote: **The Sony Rootkitted CDs incident**
    - Rootkit: "A rootkit is a collection of computer software, typically malicious, designed to enable access to a computer or an area of its software that is not otherwise allowed and often masks its existence or the existence of other software."
    - Sony CDs literally went in and installed DRM software on your computer that was near impossible to remove.
    - The cherry on top: This software was of course, vulnerable and later on exploited by various types of malware
    - All this to ensure you didn't copy over your Linkin Park CD to your mom's laptop!!!
    - **Sysinternals creator discovered this with Windows Sysinternals rootkitrevealer**
    - Check out the [legendary blog post](https://web.archive.org/web/20150317040653/http://blogs.technet.com/b/markrussinovich/archive/2005/10/31/sony-rootkits-and-digital-rights-management-gone-too-far.aspx)
    - [Video](https://www.youtube.com/watch?v=PqWjq2SdzpI)

* Also discovered a Symantec rootkit
    - Lesson: companies suck

* Types of programs in Sysinternals
    - We actually saw one of them earlier in the Windows Core Processes room (Process Explorer)
    - File and disk utilities
    - Process Utilities
    - Security Utilities
    - System information
    - etc.

<br />
<br />


## What are some of these so-called Sysinternals?

* **Sigcheck** (command-line tool)
    - Shows file verison number, timestamp information, and digital signature details such as certificates.
    - Has an option to upload desired files to VirusTotal (virus-scanning engine that runs 40+ virus scanners at once on a file)
    - Command to run sigcheck on Windows programs (the ones in `C:\Windows\System32`): `sigcheck -u -e C:\Windows\System32`


### File and Disk utilities
* **Streams** (command-line tool)
    - "The NTFS file system provides applications the ability to create alternate data streams of information. By default, all data is stored in a file's main unnamed data stream, but by using the syntax 'file:stream', you are able to read and write to alternates."
    - NTFS thing for files in windows... it's beyond stupid. But it was implemented to have compatibility with Old Mac computers. Also, it it can be used to identify files downloaded from the internet.
    - Absolutely abused by malware
    - `streams` actually only identifies the _names_ of the alternate data streams (ADS name); it doesn't give you their content.
    - In Command Prompt, you can run `more < [original file name]:[ADS name]`
    - In PowerShell, the command is instead `Get-Item [original file name] | Get-Content -Stream [ADS name]`

* **SDelete** (command-line tool)
    - A tool that _irrecoverably_ deletes files and free disk space, safely.
    - Implements a military-grade method of information deletion and sanitization, so yo know it means business.

### Networking utilities
* **TCPView** (GUI tool)
    - Shows all TCP and UDP endpoints on your system, including local and remote addresses, and the state of connections.
    - The regular (not part of Sysinternals) Windows tool "Resource monitor" (`resmon.exe`) provides a similar functionality in the "Network" tab inside the program.
    - Click on the green flag icon to filter for types of connection state filters (a good idea sometimes is to check the "Listen" filter to see what services are listening on your host.

### Process utilities
* **Autoruns** (GUI tool)
    - Comprehensive lists of all programs that _run automatically at boot or at login._
    - Image Hijacks: Lists registry settings that switch and control how a program is loaded, including hijacking executables and running them through another process. Malware devs use this to block you frmo loading stuff like Antiviruses.
    - e.g. You'll notice that on this machine, the process explorer replaced the task manager (hit Ctrl+Shift+Esc to see this). This mean that there is some kind of registry that, when loaded, runs the Sysinternals Process Explorer instead of the Windwos Task Manager. In this case, this is not malicious and is done so through a Sysinternals Process Explorer setting, which we can confirm by looking at the `Image Highjacks` tab on Autoruns.
    - The above example will also help you answer the questions in the THM room related to image highjacking (remember to sort by most recent timestamp at the top to find the "entry that was updated"

* **Process Explorer** (GUI tool)
    - Skipped for now because we already covered quite a bit of it in this room already as well as in the Windows Core Processes room.
    - Remember that you can view web traffic from services listed here. Some should have no web traffic displayed at all, unless a breach occurred. Also worth investigating IPs being communicated to (e.g run a WHOIS lookup on them)

* **Process Monitor** (GUI tool)
    - Shows detailed, real-time filesystem, registry, and process/thread activity.
    - You absolutely __need__ to apply filters in order to get anything valuable out of this (lots of process activity on any given machine), kind of like with Wireshark if you've used it before.
    - To understand stuff in ProcMon, a little bit of knowledge of the [Windows API](https://learn.microsoft.com/en-us/windows/win32/apiindex/windows-api-list) is nice, but not required

* **PsExec**
    - Program that lets you execute processes on other systems, complete with full interactivity for console applications.
    - Meant to be a replacement for telnet (the old, unencrypted and insecure version of SSH)
    - A legitimate, useful tool. Also utilized often by attackers because of its versatility.

### Security utilities
- **Sysmon** (
    - "System Monitor (Sysmon) is a Windows system service __and__ device driver that, once installed on a system, remains resident across system reboots to monitor and log system activity to the Windows event log."
    - It provides detailed information about process creations, network connections, and changes to file creation time.
    - Discussed further in the sysmon room -- [click here](https://tryhackme.com/room/sysmon)

* **WinObj** (GUI tool)
    - "WinObj is a 32-bit Windows NT program that uses the native Windows NT API (provided by NTDLL.DLL) to access and display information on the NT Object Manager's name space."


### Miscallaneous utilities

* **BgInfo**
    - Displays relevant info about a Windows computer on the desktop wallpaper
    - Useful tool for when sysadmins log into a Windows host through RDP so they can quickly see a bunch of info about it right then and there.

* **RegJump**
    - Automatically opens up the Windows Registry Editor and jumps to the specified registry path
    - Regedit can be cumbersome to navigate through, so a command like regjump `HKLM\System\CurrentControlSet\Services\WebClient` can be pretty useful.
    Note that in the above command, HKLM is Regjump's abbreviation for "HKEY_LOCAL_MACHINE" (a part of the registry that contains data used by all Windows users, e.g. drivers, autorun programs, general OS settings)

* **Strings**
    - Bascially the same idea as the `strings` program in Linux (filters out the ASCII strings it encounters in a file)
    - e.g. `strings <binary file that you want to analyze for strings]`
