#!/bin/bash

# GeoIp blocker
# Author: Dokukin Vyacheslav Olegivuch
# Email: toorrp4@gmail.com
#
# GeoIp blocker shell - the script sorts IPs by the number of requests and checks the country by GeoIP 
# if the limit of requests from this IP >= the specified value, 
# and the country is not included in the list of allowed ones, 
# then a configuration file will be created, in which such IPs  
# will be entered and connections with the NGINX server will be prohibited for them.
#This can help you in repelling L7 type DDOS attacks (SlowLoris, HTTP flood).
#
# Operating modes:
# 1) DEBUG - only shows results in the console, without blocking (default)
# 1) EXPORT - only exports results in JSON format to a file
# 3) BLOCKED - blocks unwanted IPs via NGINX configuration file
#
# Install script
# 1. Load this script 
# $ cd /tmp
# $ git clone git@gitlab.com:learning193824/bash/geoipblocker.git
# $ cp geoipblocker.sh /usr/bin
# 
# 2. Add execution rights to the script
# $ chmod +x /usr/bin/geoipblocker.sh
# 
# 3. Test the script with default settings
# $ sudo /usr/bin/geoipblocker.sh
# 
# 4. Сonfigure the script
# Change the paths to create the configuration file, depending on your system
# Default custom config path NGINX => /etc/nginx/conf.d/
# If your use VMBitrix, then custom config path NGINX => /etc/nginx/bx/settings/
# Change the list of countries from which access to the server is allowed, 
# and the request limit after which they will be blocked
# ACCESCOUNTREQ=1000
# ALLOWCOUNTRY=RU,BY,KZ
# 
# 5. Add a task to the scheduler СRON for the user root
# $ crontab -e
# */1 * * * * /usr/bin/geoipblocker.sh &>/dev/null
#
# 6. After a minute, check if the configuration file appears in NGINX and the entries in it
# $ tail -f /etc/nginx/bx/settings/geoipblocker_deny_ip.conf

# set -x

# check depends package!
if [ -f `which geoiplookup` ]; then
	
    MODE=BLOCKED
    ACCESLOGFILE=/var/log/nginx/access.log
    ACCESCOUNTREQ=10
    ALLOWCOUNTRY=RU
    NGINXCONFFILE=/etc/nginx/bx/settings/geoipblocker_deny_ip.conf
    JSONEXPORTFILE=/tmp/geoipblocker_deny_ip.json
    LOGFILE=/var/log/geoipblocker.log
    SORTLOG="$(awk '{print $1}' $ACCESLOGFILE | sort | uniq -c | sort -nr)"

    while read line
    do
        countreq=$(echo $line | awk '{print $1}')
        remoteaddr=$(echo $line | awk '{print $2}')

        if [ ! -z $remoteaddr ]; then

            country=$(geoiplookup $remoteaddr)
            countrycode=$(echo $country | awk '{print $4}' | cut -c1-2)

            # checking the number of requests
            if [ $countreq -ge $ACCESCOUNTREQ ]; then
                # check for allowed country
                echo $ALLOWCOUNTRY | grep -w $countrycode>/dev/null
                if [[ $? -gt 0 ]] && [[ $countrycode != IP ]]; then

                    case "$MODE" in
                        EXPORT)
                            # if is not exist JSON export - create a file!
                            if [ ! -f $JSONEXPORTFILE ]; then
                                touch $JSONEXPORTFILE
                            fi
                            printf '{"IP": "%s", "COUNT": "%s", "COUNTRY": "%s"}\n' $remoteaddr $countreq $countrycode >> $JSONEXPORTFILE
                        ;;	
                        BLOCKED)
                            # if is not exist NGINX config - create a file!
                            if [ ! -f $NGINXCONFFILE ]; then
                                touch $NGINXCONFFILE
                            fi

                            # write deny IP to config
                            grep -w "deny ${remoteaddr};" $NGINXCONFFILE >/dev/null

                            if [ $? -ne 0 ]; then
                                echo $? $remoteaddr
                                echo "deny ${remoteaddr};" >> $NGINXCONFFILE
                            else
                                echo "[$(date +"%d.%m.%y %H:%M:%S")] IP already exist in ${NGINXCONFFILE}" >> $LOGFILE
                            fi
                        ;;
                    esac

                    echo $remoteaddr $countreq $countrycode

                fi
            fi

        fi

    done<<<$SORTLOG

    # NGINX configs reload
    if [ $MODE == BLOCKED ]; then
        if [ -f $NGINXCONFFILE ]; then
            
            sudo nginx -t >/dev/null

            if [ $? -eq 0 ]; then
                invoke-rc.d nginx reload
                echo "[$(date +"%d.%m.%y %H:%M:%S")] NGINX configs reload" >> $LOGFILE
            else
                echo "[$(date +"%d.%m.%y %H:%M:%S")] Error - nginx: configuration files test failed!" >> $LOGFILE
                exit 1
            fi
        else
            echo "[$(date +"%d.%m.%y %H:%M:%S")] Error - not exist file config ${NGINXCONFFILE}" >> $LOGFILE
        fi
    fi

else
	echo "[$(date +"%d.%m.%y %H:%M:%S")] Error - required package geoiplookup not installed!" >> $LOGFILE
fi