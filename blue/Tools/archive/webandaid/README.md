# Webandaid
To quote the visionary singer-songwriter Taylor Swift:
> Band-aids don't fix bullet holes

Well, what if they could? This is a band-aid to slap onto the web 
applications that are often riddled with bullet holes in security
competitions. Of course, this isn't a *fix* per se, it simply delays
attackers (hopefully enough so that any issues can be fixed).

This is meant to be "first aid" for a vulnerable server. It is
intended to be set up in minutes, but is by no means a comprehensive
solution.

# Prerequisites
There are a couple of prerequisites for this program to function
properly:
 - Ability to change the listening port of the web server
 - Ability to change the listening IP address of the web server
 - Ability to add and modify firewall rules

This script requires Python 3.9 or newer.

# Instructions
First, run `configgen.py` and enter in the information about all
HTTP/HTTPS servers running on the system.

# License
Unless otherwise stated, any rules and scripts in this directory and subdirectories are 
licensed under the 
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
```
Copyright (c) 2025-2026 Yuliang Huang <https://gitlab.com/yhuang885/>
```

## OWASP Core Rule Set (CRS)
The [OWASP CRS](https://github.com/coreruleset/coreruleset) is licensed under 
the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
```
Copyright (c) 2006-2020 Trustwave and contributors. All rights reserved.
Copyright (c) 2021-2025 CRS project. All rights reserved.
```

## Coraza WAF
The [Coraza WAF](https://github.com/corazawaf/coraza) is licensed under 
the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
```
Copyright 2022 Juan Pablo Tosso and the OWASP Coraza contributors
```

## Caddy Web Server
[Caddy](https://github.com/caddyserver/caddy) is licensed under the
the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
```
Copyright 2015 Matthew Holt and The Caddy Authors
```
