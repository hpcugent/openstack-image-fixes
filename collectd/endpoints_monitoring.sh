#!/bin/bash 
# scripts return collectd commands for adding metric into queue
# last number in each row represents return code from endpoint query (0=OK, other=NotOK)

export rcfile="/opt/configrc"

source $rcfile

[ -z ${HOSTNAME_TO_RUN+x} ] && echo "Variable HOSTNAME_TO_RUN is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_ID+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_ID is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_SECRET+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_SECRET is unset." 1>&2 && exit 1
[ -z ${KEYSTONE_ENDPOINT+x} ] && echo "Variable KEYSTONE_ENDPOINT is unset." 1>&2 && exit 1
[ -z ${ALL_ENDPOINTS+x} ] && echo "Variable ALL_ENDPOINTS is unset." 1>&2 && exit 1

#if not running from correct host exit the script
hostname|grep "$HOSTNAME_TO_RUN" &>/dev/null || exit 1


#get token
OS_TOKEN=`curl -s --fail -i -D - --max-time 10 -o /dev/null \
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
 $KEYSTONE_ENDPOINT/auth/tokens 2>&1|grep X-Subject-Token`
[ $? -ne 0 ] && echo "Unable to get token from keystone." 1>&2

export OS_TOKEN="$(echo $OS_TOKEN |awk '{print $2}'|sed 's/\r$//')"

#check endpoints by curl
for i in $ALL_ENDPOINTS
do
        endpoint="`curl -g -q -s --fail -o /dev/null \
                -H \"X-Auth-Token: $OS_TOKEN\" \
                --max-time 10 \
                --user-agent \"curl-healthcheck\" \
                --write-out \"%{remote_port}\n\" \
                $i`"
                #--write-out "%{http_code} %{remote_ip}:%{remote_port} %{time_total} seconds\n" \
        retcode=$?
#       echo $retcode $endpoint
        echo "PUTVAL `hostname`/endpoints/commands-port_$endpoint interval=60 N:$retcode"
done
