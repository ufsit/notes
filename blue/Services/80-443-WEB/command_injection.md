# Command Injection
* an attacker injects command into a remote system

**Example**
* suppose we have the following website: `https://realy-bad-website.com/itemStatus?itemID=1234&itemNum=45`
* Further, suppose the back-end application is running as follows:
  * `itemReport.p1 1234 45`
* If this is true, we can provide a command instead of expect input in the `itemID` field
  * `itemID=& echo asdf &`
  * `stockreport.01 & echo asdf & 45`
  * the system will interpret the input as 3 different commands, each separated by the `&` symbol
* We can expect an error out of this, may be indicative of a successful command injection

# Blind Attack
* Often times, we may not know whether our injection worked (no output from the app)
* So, we're interested in injecting a command that we can easily know whether it worked
  * a typical strat is to ping ourselves; we can tell it works because we can either receive the ping or see that the page took a second to load
  * `& ping -c <own_ip> &`
* If we can verify that the injection worked, we can ask the system to run a command and save the results to a new file that is accessible from the site
  * `& whoami > /var/www/static/whoami.txt`
  * we may be able to navigate to this address and inspect results