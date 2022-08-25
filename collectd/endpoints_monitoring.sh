#!/bin/bash 
# scripts return collectd commands for adding metric into queue
# last number in each row represents return code from endpoint query (0=OK, other=NotOK)

export rcfile="/opt/configrc"

source $rcfile

[ -z ${HOSTNAME_TO_RUN+x} ] && echo "Variable HOSTNAME_TO_RUN is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_ID+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_ID is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_SECRET+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_SECRET is unset." 1>&2 && exit 1
[ -z ${KEYSTONE_ENDPOINT+x} ] && echo "Variable KEYSTONE_ENDPOINT is unset." 1>&2 && exit 1

#if not running from correct host exit the script
hostname|grep "$HOSTNAME_TO_RUN" &>/dev/null || exit 1

#get token
OS_TOKEN=$(curl -s --fail -i -D - --max-time 10 -o /dev/null \
  -H "Content-Type: application/json" \
  -d "
{
    \"auth\": {
        \"identity\": {
            \"methods\": [
                \"application_credential\"
            ],
            \"application_credential\": {
                \"id\": \"$OS_APPLICATION_CREDENTIAL_ID\",
                \"secret\": \"$OS_APPLICATION_CREDENTIAL_SECRET\"
            }
        }
    }
}" \
 "$KEYSTONE_ENDPOINT/auth/tokens" 2>&1|grep X-Subject-Token)
 retcode="$?"
[ $retcode -ne 0 ] && echo "Unable to get token from keystone." 1>&2

OS_TOKEN="$(echo "$OS_TOKEN" |awk '{print $2}'|sed 's/\r$//')"
export OS_TOKEN

ALL_ENDPOINTS="$(curl --fail -L -g -q -s --max-time 10 \
  -H "Content-Type: application/json" \
  -d "
{
    \"auth\": {
        \"identity\": {
            \"methods\": [
                \"application_credential\"
            ],
            \"application_credential\": {
                \"id\": \"$OS_APPLICATION_CREDENTIAL_ID\",
                \"secret\": \"$OS_APPLICATION_CREDENTIAL_SECRET\"
            }
        }
    }
}" \
 "$KEYSTONE_ENDPOINT/auth/tokens" | \
        python3 -c "import json; import sys; data=json.load(sys.stdin);
for a in data['token']['catalog']: 
  for b in a['endpoints']: 
    if b['interface']=='public': 
      print(b['url'])")"

#modify endpoints for curl query
ALL_ENDPOINTS="$(echo $ALL_ENDPOINTS|tr " " "\n"|\
                sed 's/:13005\/.*/:13005\//g'|\
                sed 's/:13004\/.*/:13004\//g'|\
                sed 's/:13776\/v2\/.*/:13776\/v2\//g'|\
                sed 's/:13776\/v3\/.*/:13776\/v3\//g'|\
                sed 's/:13786\/v1\/.*/:13786\/v1\//g'|\
                sed 's/:13786\/v2\/.*/:13786\/v2\//g')"

#check endpoints by curl
for i in $ALL_ENDPOINTS
do
        endpoint="$(curl -g -q -s --fail -o /dev/null \
                -H "X-Auth-Token: $OS_TOKEN" \
                --max-time 10 \
                --user-agent "curl-healthcheck" \
                --write-out "%{remote_port}\n" \
                "$i")"
                #--write-out "%{http_code} %{remote_ip}:%{remote_port} %{time_total} seconds\n" \
        retcode=$?
#       echo $retcode $endpoint
        echo "PUTVAL $(hostname)/endpoints/commands-port_$endpoint interval=900 N:$retcode"
done
