#  Windows Core Processes (TryHackMe)

* PROGRAM VS PROCESS
    - A _process_ is a program in execution.
    - A _program_ is simply the set of instructions (i.e. source code / binary file) for things that you want to run on a computer.

* **Point of this room**:
    - To understand what normal behavior in Windows processes looks like

* Windows and Linux PIDs work slightly different. In Linux, PIDs follow a more (sensical) incremental approach, Windows PID assignment is ~quirky and obscure~
    - This is why svchost.exe, which is a child process of services.exe, has a lower number PID which is dumb.

*  To view running processes in Linux -- use `ps aux` command
    - `ps` is a program for seeing a _snapshot_ of the current running processes

* If the same program has multiple processes running, each will have its own unique PID

* What is the Windows Registry?
    - Look up the Wikipedia definition
    - We'll see more in the Windows Forensics room later

* For all the following processes:
    - Have a general idea of what its normal properties look like (reference the TryHackMe room when needed)
    - For most of these, a dead giveaway is their command line path and/or current directory NOT being `C:\Windows\System32`

* System process on Windows (nstokrnl.exe)
    - `ntoskrnl.exe` -- Does anyone know what this might mean?
    - Always PID 4 (Notice the properties of all PIDs in Windows -- always divisible by 4)
    - 1 DOLLAR QUESTION: What is the Windows PID 0 process?
    - Weird properties
    - https://superuser.com/questions/1182187/why-is-system-pid-4-not-pid-1
    - Compromised System process: https://security.stackexchange.com/questions/230841/system-process-pid-4-attempt-to-connect-to-many-risky-ips-using-local-port-137

<br />

## The Core Services

* **smss.exe (Session Manager subsystem AKA Windows Session Manager)** -- spawned by System process (ntoskrnl.exe)
    - By session, we mean an instance of a user being logged in
    - Process starts in kernel mode
    - Session 0 -- an isolated session for the operating system (not belonging to users)
    - smss.exe gets employed in each new user logon session
    - Its parent process is the System service (PID 4)

* **csrss.exe (Client Server Runtime Process)** -- spawned by smss.exe
    - Always running, critical to system operation,
    - This process is responsible for making the Windows API available to other processes, mapping drive letters, hanlding shutdown process...
    - Recall that crss.exe and winlogon.exe are called from smss.exe at startup for session 1
    - Note that when inspecting its properties, its parent PID is a "nonexistent process" because smss.exe self-terminate itself after it copies itself into the respective session

* **wininit.exe (Windows Initialization process)** -- spawned by smss.exe
    - Works in session 0
    - Responsible for launching services.exe, lsass.exe, and lsaiso.exe in session 0
    - Another critical process, always runs in the background
    - Just like csrss.exe, its parent is nonexistent because smss.exe terminates itself after

* **services.exe** (Service Control Manager process) -- spawned by wininit.exe
    - Handles loading services, interacting with services, starting/ending services, etc.
    - Since it's created by wininit.exe in session 0 (the operating system session -- AKA not the user session), there's only 1 instance of it
    - Hint: more than 1 instance is unusual activity
    - run `sc.exe` in Windows CMD to see the database it uses

* **svchost.exe** -- spawned by services.exe
    - Since svchost.exe will always have multiple running processes on any Windows system, this process has been a target for malicious use.
    - Adversaries create malware to masquerade as this process and try to hide amongst the legitimate svchost.exe processes.
    - They can name the malware svchost.exe or misspell it slightly, such as scvhost.exe.
    - By doing so the intention is to go under the radar. Another tactic is to install/call a malicious service (DLL).
    - Check for the `-k` in the binary path to service DLLs under svchost.exe
    - Multiple svchhosts can get spawned per system (this is normal)
    - Further reading: https://www.hexacorn.com/blog/2015/12/18/the-typographical-and-homomorphic-abuse-of-svchost-exe-and-other-popular-file-names/

* **lsass.exe (Local Seucirty Authority Subsystem)** -- spawned by wininit.exe
    - Responsible for enforcing the **security policy** on the system
    - Verifies user logons, password changes, password policies
    - Creates access tokens for SAM (Security Account Manager), Active Directory, and NETLOGON
    - **Cool note: the popular tool `mimikatz` (used a lot in Windows hacking) actually mimic this process to hide in plain sight.**
    - Only one instance per system
    - Further reading: https://yungchou.wordpress.com/2016/03/14/an-introduction-of-windows-10-credential-guard/

* **winlogon.exe** -- spawned by smss.exe
    - Handles the Secure Attention Sequence (**this is what is responsible for Ctrl+Alt+Delete**)
    - Loads user profile through userinit.exe
    - Also loads locks screen, runs the user's screensaver
    - In the Windows Registry, its 'Shell' attribute should have a value of `explorer.exe`

* **explorer.exe**
    - Literally what lets you look at your files and folders.
    - Without it, you also can't have your taskbar, Start Menu, etc.
    - Nonexistent parent process (because userinit.exe self-terminates)
    - **Your typical user programs will be listed as child processes of explorer.exe**
    - Has a filepath of `C:\Windows\explorer.exe` (not in System32)
    - Would be suspicious if this process had any outbound connections (**SHOW EXAMPLE with sysinternals Process Explorer**)
