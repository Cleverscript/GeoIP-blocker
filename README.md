# GeoIp blocker

GeoIp blocker shell - the script sorts IPs by the number of requests and checks the country by GeoIP 
if the limit of requests from this IP >= the specified value, 
and the country is not included in the list of allowed ones, 
then a configuration file will be created, in which such IPs  
will be entered and connections with the NGINX server will be prohibited for them.
This can help you in repelling L7 type DDOS attacks (SlowLoris, HTTP flood)

## Operating modes:
1. DEBUG - only shows results in the console, without blocking (default)
2. EXPORT - only exports results in JSON format to a file
3. BLOCKED - blocks unwanted IPs via NGINX configuration file

Install script
1. Load this script 
$ cd /tmp
$ git clone git@gitlab.com:learning193824/bash/geoipblocker.git
$ cp geoipblocker.sh /usr/bin

2. Add execution rights to the script
$ chmod +x /usr/bin/geoipblocker.sh

Test the script with default settings
$ sudo /usr/bin/geoipblocker.sh

Сonfigure the script
Change the paths to create the configuration file, depending on your system
Default custom config path NGINX => /etc/nginx/conf.d/
If your use VMBitrix, then custom config path NGINX => /etc/nginx/bx/settings/
Change the list of countries from which access to the server is allowed, 
and the request limit after which they will be blocked
ACCESCOUNTREQ=1000
ALLOWCOUNTRY=RU,BY,KZ

Add a task to the scheduler СRON for the user root
$ crontab -e
*/1 * * * * /usr/bin/geoipblocker.sh &>/dev/null

After a minute, check if the configuration file appears in NGINX and the entries in it
$ tail -f /etc/nginx/bx/settings/geoipblocker_deny_ip.conf