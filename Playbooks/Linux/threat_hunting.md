# Linux Threat Hunting

Ideally, you should be logged into the target machine as a user that can escalate to root. Here are what you should look out for:

1. **User misconfigurations**: For this you will use a tool I (AN) developed. You can read [this](../users.md) to understand the vulns in more detail.
    <details>
    <summary>Click here to see the steps</summary>
    <ol>
       <li> <code>git clone https://github.com/pyukey/BlueDaBaDee.git</code></li>   
        If you do not have access to the internet nor git, there are some backup plans. You can either get the repo locally and <code>scp</code> it over. Or, host a web server locally via <code>python3 -m http.server</code> and then on the target machine curl the files you want. 
       <li> <code>cd BlueDaBaDee/Linux/usrs</code></li>
       <li> <code>chmod 764 *.sh</code></li>
       <li> <code>./listUsersColor.sh</code></li>   
       You can read <a href="#listuserscolorsh">this</a> to understand how to interpret the results.
    </ol>
    </details>
2. **Privilege escalation**: The go-to tool for this is [LinPEAS](https://github.com/peass-ng/PEASS-ng/tree/master/linPEAS). Follow the instructions to run it, and then figure out how to patch each of the vulns.
3. **Processes**:
4. **Network connections**:
5. **Rootkits**:
6. **Service misconfigurations**: