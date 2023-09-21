#!/bin/bash

# GeoIp blocker shell
# Author: Dokukin Vyacheslav Olegivuch
# Email: toorrp4@gmail.com
#
# The script sorts IPs by the number of requests and checks the country by GeoIP 
# if the limit of requests from this IP >= the specified value, 
# and the country is not included in the list of allowed ones, 
# then a configuration file will be created, in which such IPs  
# will be entered and connections with the NGINX server will be prohibited for them
#
# Operating modes:
# 1) DEBUG - only shows results in the console, without blocking (default)
# 1) EXPORT - only exports results in JSON format to a file
# 3) BLOCKED - blocks unwanted IPs via NGINX configuration file
#
# If your use VMBitrix, then custom config path NGINX => /etc/nginx/bx/settings/

# set -x

# check depends package!
if [ -f `which geoiplookup` ]; then
	
    MODE=BLOCKED
    ACCESCOUNTREQ=5
    ALLOWCOUNTRY=RU
    ACCESLOGFILE=/var/log/nginx/access.log
    NGINXCONFFILE=/etc/nginx/bx/settings/geoipblocker_deny_ip.conf
    JSONEXPORTFILE=/tmp/geoipblocker_deny_ip.json
    LOGFILE=/var/log/geoipblocker.log

    awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | 
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
                                echo "deny ${remoteaddr};" >> $NGINXCONFFILE
                            else
                                echo "[$(date +"%d.%m.%y %H:%M:%S")] IP ${remoteaddr} already exist in ${NGINXCONFFILE}" >> $LOGFILE
                            fi
                        ;;
                    esac

                    echo $remoteaddr $countreq $countrycode
                fi
            fi

        fi

    done

    # NGINX configs reload
    if [ $MODE == BLOCKED ]; then
        if [ -f $NGINXCONFFILE ]; then
            
            sudo nginx -t >/dev/null

            if [ $? -eq 0 ]; then
                #invoke-rc.d nginx reload
		systemctl reload nginx
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