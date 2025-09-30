# 📓🔐 NIST 800-61 NOTES (for CyberForce) 🔐📓

Why are we reviewing an incident response framework?

A: Because the minute we get network access, we are responding to an incident.
Although there's no live attack going on until Nov. 5th for CyberForce, there's already been a breach in our system.

See [attack scenario](https://cyberforce.energy.gov/cyberforce-competition/scenario/) for more info.

Some general pointers:
- Establishing a successful incident response procedure requires planning and resources.
- Understanding & identifying attacks at early stages is key to preventing subsequent compromise (important aspect for CyberForce!!)
- Continously monitoring for attacks is essential.
- Know how to prioritize different incidents -- not all are equally important.
- Have effective methods of collecting, analyzing, and reporting data.
- Keep good relations and communications with related teams in the organization.


## SECTION 1: STRUCTURE

Sections in the NIST 800-61:

2. Organizing a Computer Security Incident Response Capability
3. Handling an Incident
4. Coordination and Information Sharing





## SECTION 2: Organizing a Computer Security Incident Response Capability

* "Event"
    - An _event_ is any observable occurrence in a system or network.
    - e.g. useer connecting to a file share, web requests, sending emails, firewall blocking a connection...

* "Adverse event"
    - An _adverse event_ is an event with negative consequences
    - e.g. system crashes, packet floods, unauthorised use of system privileges, execution of malware, unauthorized access to sensitive data...

* "Incident"
    - A computer security _incident_ is a violation or imminent threat of violation of computer secuirty policies, acceptable use policies, or standard security practices
    - e.g. attacker DDoSing a web server, user executing malware, attacker obtaining sensitive data and threatening with ransom, user exposes sensitive info over internet

* Incident response personnel
    - **Have a team captain** -- this should be someone with good communication skills. Pick someone on your team to be this.
    - **Have a technical lead** -- this person should have good technical skills. Whoever this is for your team, have them be in charge of overseeing the technical details of everyone's work
    - **Team members** -- everyone on the team should have a general knowledge of skills that are involved in system  administration, network administration, programming, and technical support.
    - It is not necessary for every team member to be a technical expert.
    - Overall, it is a good idea to to have team members specialize in particular areas -- e.g. some with malware, others with forensics, others with network intrusion detection.

* Selecting an incident response mode
    - For CyberForce, it is especially important to model our incident response based on the infrastructure we have in front of us.
    - We need to prioritize certain things in our approach based on the systems we have, i.e. special attention needs to be given to ICS systems
    - To summarize: Rather than apply a one-size-fits-all approach, we need to look at the network topology in front of us, determine what can/has been attacked, and model our response accordingly.

* Note taking
    - It is **very, very important** that _everyone_ on the team takes extremely detailed notes on everything they do and find with each system in the network.
    - If you make a change or discover something that you don't write down, it is a signficant time loss and potential point loss for your team
    - Make sure your note-taking system lets you easily share and view notes from the rest of the team.





## SECTION 3: HANDLING AN INCIDENT

**The incident response cycle**
1. Preparation
2. Detection and Analysis
3. Containment and Recovery
4. Post-incident activity (securing the network, writing our report)

Steps 2 and 3 cycle back between each other, e.g. you may find a host infected by malware and fix it/contain it, but you have to detect and analyze potential effects on other systems from the malware.

### Section 3.1: Preparation

* Know the external teams that you will be staying in contact with during an incident -- in our case, the orange team (C-suite), white team (network admins), and green team (clients)

* Issue/note tracking system -- not only to share notes, but to track status of various incidents/vulnerabilities with your network

* Ensure you have somewhere to store forensics files, e.g. preserving logs for future review, preserving potential malware for future analysis, etc.

* Have a port list -- a list with commonly used ports __as well as__ common Trojan ports

* Know how to find documentation for OSs, applications, protocols, and intrusion detection and antiviruses.
    - [The STIG database](https://public.cyber.mil/stigs/downloads/) is useful for security-specific configuration guides and documentation.

* Have cryptographic hashes of critical files to speed up incident analysis, verification, and eradication.

* Elements for preventing incidents
    - **Routine risk assessments** -- especially important for Cyberforce ICS systems. We need to identify what parts of the system pose the most risk, and how they could be exploited or abused.
    - **Host security** -- All hosts should be hardened appropriately using standard configurations (*see and browse through the STIG database above -- this is a great resource for hardening guides*)
    - Hosts should have auditing enabled and should log significant security-related events.
    - **Network security** -- The network perimeter should be configured to deny all activity that is not __expressly permitted__.
    - **Malware prevention** -- Software to detect and stop malware should be deployed throughout the organization.
    - Malware detection should be deployed at the host level (e.g. server and workstation OS), the application server level (e.g. email server, web proxies), and application client level (e.g. email clients, instant messaging clients)
    - **User awareness and training** -- Make users aware of policies and procedures regarding appropriate use of network systems and programs. __Sare the applicable lessons learned from previous incidents.__

### Section 3.2: Detection and analysis

Incidents can occur in countless ways, so __it is infeasible to make step-by-step instructions on how to handle every incident.__
We have to be prepared to handle any incident using a general approach that involves a lot of constant communication and meticulous notekeeping.

Nevertheless, there are a few common methods of attack that we should __always__ be prepared for:

1. **External/removable media**
    - e.g. malicious code spreading onto a system through a USB drive

2. **Attrition**
    - An attack that employs brute-force methods to compromise/degrade/destroy systems or networks
    - e.g. DDoS, live password brute forcing, live authentication brute forcing

3. **Web**
    - Attack executed from a website or on a web-based application
    - e.g. XSS (Cross-Site Scripting), malicious redirect, SSRF (Server-Side Request Forgery)...

4. **Email**
    - e.g. exploit code disguised as an attached document, malicious website in the body of an email

5. **Impersonation**
    - An attack where something benign (innocent) is replaced with something malicious
    - e.g. spoofing on the network, MitM (Man in the Middle) attacks, rogue wireless access points, SQLi (SQL injection)...

6. **Improper usage**
    - Any incident resulting from a violation of an organization's acceptable use policies
    - e.g. user installs a file-sharing software that could potentially lead to loss of sensitive data, illegal activities being being performed on the system (e.g. torrenting pirated software)

7. **Loss or theft**
    - Loss of a computing device or media used by the organization
    - e.g. losing cell smartphone, laptop, authentication token...


#### 3.2.2 Signs of an incident
Often, the most challenging part is accurately detecting that an incident happened in the first place.
Not only that, but it can also be hard to identify the type of incident, the extent, and the magnitude of the problem.

What makes this so challenging is a combination of three factors:

1. Incidents may be detected through many different means, with varying levels of detail and correctness
    - Automated detection capabilities include network-based and host-based IDS (Intrusion Detection Systems) and IPS (Intrusion Prevention Systems) software, antiviruses, and log analyzers
    - Some incidents have obvious signs that let us detect them, others may be impossible to.

2. The volume of incidents is typically high
    - e.g. It is not uncommon for an organization to receive thousands or even millions of intrusion detection alerts per day
    - Hopefully it won't be that many for CyberForce lul

3. Deep, specialized, technical knowledge and experience is often necessary for proper and efficient analysis of incident data
    - Sometimes, we have to get creative and do what we can

* Signs of an incident fall into two main categories:
    - **Precurosors**: Signs that an incident may occur in the future. Not that common.
    - **Indicators**: Signs that an incident may have occured or is occuring right now. Significantly more common to find than precursors.
    - For CyberForce, keep these two types of signs in mind as you explore and analyze your network.

Examples of precursors:
- Web server log entries that show usage of a vulnerability scanner
- An announcement of a new exploit that targets a vulnerability of your organization's mail server
- A threat from an attacker group stating that they will be attacking your organization

Exampels of indicators:
- Network IDS (Intrusion Detection System) alerts when a buffer overflow attempt occurs against a database server
- Antivirus software alerts when it detects that a host is infected with malware
- A sysadmin (system administrator) sees a filename with unusual characters
- A host records an auditing configuration change in its log.
- An application logs multiple failed login attempts from an unfamiliar remote system
- An email administrator sees a large number of bounced emails with suspicious content
- A network admin notices unusual deviation from usual network traffic flows
- Many, many more


#### 3.2.3 Sources of precursors and indicators
To see more detailed explanations for each of the terms in the list below, __check page 27 of the NIST 800-61 specification.__
Without going into too much detail, here is a list of common sources that intrusion signs (precursors and indicators) can be obtained from:

ALERT SOURCES:
- IDPSs (Intrusion Prevention and Detection Systems -- check NIST 800-61 pg. 27)
- SIEMs (Security Information and Event Management systems -- check NIST 800-61 pg. 27)
- Antivirus and antispam software
- File integrity checking software
- Third party monitoring services

LOG SOURCES:
- Operating System, network service, and application logs
- Network device logs (e.g. from routers or firewalls). Not super ccommon because of their small amount of details.
- Network flows (pg. 28 on NIST 800-61 for more detail)

PUBLICLY AVAILABLE SOURCES:
- Information on new vulnerabilities and exploits

PEOPLE SOURCES:
- People from within the organization (they may speak up and mention warning signs, make sure to ask them how confident they are about the accuracy)
- People from other organizations (other orgs may mention that one of our systems is attacking theirs, for example)


Note for CyberForce: See if these types of sources are in your network during competition. If not, think critically about which ones you should implement.
Generally speaking, you're gonna wanna have antivirus software for most hosts (check the UF 2019 report for concrete examples of this for both Windows and Linux hosts).
Research potential software that provides these capabilities.

* Speaking of the 2019 UF CyberForce report, take a careful look at the Splunk and Microsoft Active Directory domain controller that they employed.
    - The Splunk deployment is an example of implementing a SIEM system.
    - They recognized a lacking element of event monitoring and logging the network, and they deemed it appropriate to implement a new machine on the network to fix this.
    - In general, organizations must have a baseline level of logging on all systems, and an _even higher_ baseline on critical systems such as ours for CyberForce

* Critical difference between IDPSs and SIEMS
    - Most IDPS products use a __database of attack signatures__ to identify malicious activity within the network traffic they analyze.
    - SIEMs are similar, except that they base their alerts based on __log data.__ They typically don't inspect network packets.


#### 3.2.4 Incident Analysis
Incident detection and analysis would be easy if precursors/indicators were guaranteed to be accurate -- this is not the case.

* Note that even if an indicator is accurate, this does not mean an incident has occured
    - Some indicators, such as a server crash or modification of important files, can happen for many other reasons than a security incident.
    - Nevertheless, it is useful to treat indicators seriously and to act with suspicion.

* Sometimes, determining if an event is actually an incident is a matter of judgement
    - **This is why it is important that you come to a conensus with your team** -- talk to them when events/signs get discovered.


**When the team believes an incident has occured:**
1. Determine the scope (e.g. which networks, systems, or applications have been affected)
2. Determine who or what originated the incident
3. Determine _how_ the incident is occuring (e.g. what tools or attack methods are being used, what vulnerabilities are being exploited)o

Performing initial analysis is challenging.
The following are some recommendations for making analysis easier and more efficient:

- **Profile Networks and Systems**
    - _Profiling_ means measuring the characteristics of expected activity so that changes can be more easily identified
    - e.g. run file integrity checking software on hosts to derive hashes/checksums for critical files. __These can then be checked during CyberForce red team phase to quickly detect tampering.__
    - e.g. monitoring network bandwidth usage to determine what the average and peak usage levels are at various times of the day.
    - In practice, profiling can often be difficult and not extremley accuarate. This is why it is only one part of our broader analysis.

- **Understand Normal Behaviors**
    - Study your networks, systems, and applications to determine their _normal_ behavior when they're being used so that _abnormal_ behavior can be recognized more easily
    - e.g. conduct frequent reviews of logs entries and security alerts during normal periods of time.
    - We often look at logs and alerts when there is an ongoing attack, but it is just as important to know what they look like when there isn't one.
    - Note that __logs can be very long, so some filtering should be involved to condense them to a reasonable size.__
    - If we check logs frequently, then over time, we will get better at noticing trends and changes.

- **Create a Log Retention Policy**
    - Information regarding an incident may be recorded in several places, e.g. firewall, IDPS, application logs...
    - Creating and implementing a retntion policy that specifies how long data should be maintained can be __extremley helpful__ in analysis.
    - e.g. older log entries may show reconaissance activity or previous instances of similar attacks
    - e.g. incidents may not be discovered until days, weeks, or even months later.
    - The length of time to maintain log data is dependent on factors such as volume of data, organizations' policies, and more.
    - Look up _NIST 800-92: Guide to Computer Security Log Management_ for recommendations on this

- **Perform Event Correlation**
    - Evidence of an incident __may be captured in several logs__ that each contain different types of data
    - e.g. a firewall log may have the source IP address that was used, whereas an application log may contain a username.
    - It is __very important__ that these separate sources of evidence be analyzed to determine if they are part of the same incident, or if they are two separate incidents.

- **Keep All Host Clocks Synchronized**
    - Do all hosts have the same time? If not, consider using protocols such as NTP (Network Time Protocol) to make this be the case.
    - This is important because we don't want to have confusion over the timeline of events when analyzing logs.
    - e.g. We don't want to have one type of log report an incident at 12:04pm, while another reports it at 12:01pm

- **Maintain and Use a Knowledge Base of Information**
    - This is especially important for CyberForce
    - No need to overcomplicate it, a simple approach can be effective (e.g. shared text document, spreadsheet..)
    - Knowledge base should also contain a variety of information, such as the significance and explanations of the validity of precursors and indicators.

- **Use Internet Search Engines for Fesearch**
    - e.g. if there's suspicious traffic on port 22919", a search for "TCP port 22919" on a search engine could provide useful results.

- **Run Packet Sniffers to Collect Addition**
    - Sometimes, indicators do not record enough data to understand what is happening. (e.g. only capturing some of the malicious
    - If an incident is ocurring over the network, sometimes the best thing to do is to run a sniffer (e.g. __Wireshark__)
    - You will likely want to apply __filters__ to the sniffing to ensure you can spot the incident-related traffic (e.g. filter by port, IP, etc.)

- **Filter the Data**
    - There's not enough time to review and analyze all indicators
    - At a minimum, the most suspicious activity should be investigated
    - An effective strategy for filtering: Discard the _categories_ of indicators that tend to be insignificant.
    - Another effective strategy for filtering (riskier): Show only the most important _categories_ of indicators.

#### 3.2.5 Incident Documentation
* An incident response team that suspects an incident has occurred should __immediately__ start recording all facts about the incident.
    - A simple "logbook" is an effective medium for this.
    - Laptops, audio recorders, and digital cameras can also serve this purpose.

* Documenting system events, conversations, and observed file changes makes incident response many, many times better.
    - __Every step taken from the time of incident detection to resolution should be documented and timestamped.__

* Documentation tip: Work in teams of two
    - One person can perform the technical tasks, while the other person records and logs events.

* Issue tracking system
    - "Issues" in the case of CyberForce, could be kept track of on a per-machine basis.
    - **My idea:** have dedicated sections of notekeeping on each machine that we have in our network.
    - Under each of those sections of machines, we list the different _issues_ we find in them
    - Note that this will be a __separate resoruce from the knowledge base__

Here are some things the issue tracking system should contain info about:

- Current status of the incident ("new", "in progress", "forwarded for investigation", "resolved", etc.)
- A summary of the incident
- Indicators related to the incident
- Actions taken by all incident handlers on this incident
- Impact assessment (see section 3.2.6, below) related to the incident
- List of evidence gathered (see section 3.3.2)
- General comments from incident handlers
- Next steps to be taken

**Important**:
Make sure you safeguard incident data and restrict access to it because this often contains sensitive info,
e.g. data on exploited vulnerabilities, recent security breaches, users that may have performed inappropriate actions.
Only authorized personnel should have access to the incident database.

#### 3.2.6 Incident Prioritization
Incidents should __not__ be handled on a first come, first serve basis because we have limited resources.
Instead, try to prioritized incidents based on the following:

* Functional impact of the incident (e.g. how does it affect users, how does it affect business functionality, how could it impact __in the future__)
* Informational impact of the incident (how does it affect the Confidentiality, Integrity, and Availability CIA of your/other organizations?)
* Recoverability from the incident (In what ways can we recover? How long will it take to recover? Is it worth investing resources in it? Is it even possible to recover?)

Definition -- __Business impact:__
    - The __business impact__ is the combination of the functional impact and the informational impact of an incident.

**Functional Impact Categories:**
- __None:__ No effect on the organization's ability to provide all services to all users.
- __Low:__ Minimal effect; organization can still provide all critical services to all users but has _lost efficiency._
- __Medium:__ Organization has lost ability to provide a critical service to a subset of system users
- __High:__ Organization is no longer able to provide some critical services to any users

**Information Impact Categories:**
- __None:__ No information was exfiltrated, changed, deleted, or otherwise compromised
- __Privacy Breach:__ Sensitive Personally Identifiable Information (PII) of taxpayers, employees, b
- __Proprietary Breach:__ Unclassified proprietary info, such as Protected Critical Infrastructure Information (PCII), was accessed or exfiltrated.
- __Integrity Loss:__ Sensitive or properietary information was changed or deleted.


**Recoverability Effort Categories:**
- __Regular:__ Time to recovery is predictable with existing resources
- __Supplemented:__ Time to recovery is predictable with additional resources
- __Extended:__ Time to recovery is unpredictable; additional resources/outside help is needed
- __Not Recoverable__: Recovery from the incident is not possible (e.g. sensitive data exfiltrated, posted publicly); launch investigation

#### 3.2.7 Incident notification
I am ommitting notes for this section with the assumption that CyberForce will be specifying their own information for notifying about incidents.

### Section 3.3: Containment, Eradication, Recovery

#### 3.3.1 Choosing a containment strategy
* Most incidents require _containment,_ which we want to do before an incident overwhelms resources or increases damage.
    - An essential part of containment is decision-making:
    - Do we shut down a system?
    - Do we just disconnect it from the network?
    - Do we only disable certain functions of that system?

Containment strategy can vary a lot, e.g. containment strategy for email-borne malware is very different from a network DDoS attack.

Criteria for determining an appropriate containment strategy include:
- Potential damage to and theft of resources
- Need for evidence preservation
- Service availability (e.g. network connectivity, services provided to external parties)
- Time and resources needed to implement the strategy
- Effectiveness of containment (e.g. partial containment, full containment)
- Duration of the solution (e.g. emergency workaround, temporary workaround, or permanent solution)

* Containment strategy: __Sandboxing__
    - Risky, potentially with legal consequences
    - Involves setting up a sandbox in which an attacker can still perform certain monitored, __contained__ activity
    - e.g. Disconnecting a compromised system from other hosts on the network
    - This is dangerous; an escape from this sandbox could lead to escalation and compromise of other systems.
    - Note that sometimes sandboxing a host can trigger attacker traps, e.g. encrypting filesystem if detecting sandboxing.

#### 3.3.2 Evidence Gathering
A detailed evidence log should be kept (remember, this evidence log forms a part of the issue tracking system) which includes the following:

- Identifying information (e.g. location, serial number, model number, hostname, MAC address, IP address)
- Name, title, and phone number of each individual who collected or handled evidence during the investigation
- Time and date (including timezone) of each occurrence
- Location where evidence was stored

* Forensics is  important when doing anything related to evidence gathering.






## Summary of Reccomendations for Incident Handling

- Acquire tools, resources and skills that may be valuable during incident handling.

- Prevent incidents from occurring by ensuring that networks, systems, and applications are sufficiently secure.

- Identify precursors and indicators through alerts generated by several types of security software.

- Require a baseline level of logging and auditing on all systems, and a higher baseline level on all critical systems.

- Profile networks and systems.

- Understand the normal behaviors of networks, systems, and applications.

- Perform event correlation

- Keep all host clocks synchronized.

- Maintain and use a knowledge base of information.

- Start recording all information as soon as the team suspects that an incident has occurred (Record EVERY step)

- Safeguard incident data.

- Prioritize handling of the incidents based on the relevant factors.

- Include provisions regarding incident reporting in the organization’s incident response policy.

- Establish strategies and procedures for containing incidents.

- Follow established procedures for evidence gathering and handling.

- Capture volatile data from systems as evidence.

-  Hold lessons learned meetings after major incidents.
