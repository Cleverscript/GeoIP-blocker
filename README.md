# GeoIp blocker

GeoIp blocker shell - the script sorts IPs by the number of requests and checks the country by GeoIP 
if the limit of requests from this IP >= the specified value, 
and the country is not included in the list of allowed ones, 
then a configuration file will be created, in which such IPs  
will be entered and connections with the NGINX server will be prohibited for them

## Operating modes:
1. DEBUG - only shows results in the console, without blocking (default)
2. EXPORT - only exports results in JSON format to a file
3. BLOCKED - blocks unwanted IPs via NGINX configuration file

If your use VMBitrix, then custom config path NGINX => /etc/nginx/bx/settings/