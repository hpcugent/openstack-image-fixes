#!/bin/bash

export rcfile="/opt/configrc"

#below timeouts in seconds
export deletion_timeout=300  #5min
export creation_timeout=1800 #30min

source $rcfile
[ -z ${HOSTNAME_TO_RUN+x} ] && echo "Variable HOSTNAME_TO_RUN is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_ID+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_ID is unset." 1>&2 && exit 1
[ -z ${OS_APPLICATION_CREDENTIAL_SECRET+x} ] && echo "Variable OS_APPLICATION_CREDENTIAL_SECRET is unset." 1>&2 && exit 1
[ -z ${OS_PROJECT_ID+x} ] && echo "Variable OS_PROJECT_ID is unset." 1>&2 && exit 1
[ -z ${KEYSTONE_ENDPOINT+x} ] && echo "Variable KEYSTONE_ENDPOINT is unset." 1>&2 && exit 1
[ -z ${HEAT_ENDPOINT+x} ] && echo "Variable HEAT_ENDPOINT is unset." 1>&2 && exit 1
[ -z ${HEAT_JSON+x} ] && echo "Variable HEAT_JSON is unset." 1>&2 && exit 1

#if not running from correct host exit the script
hostname|grep "$HOSTNAME_TO_RUN" &>/dev/null || exit 1

#define stackname
stackname="teststack-`hostname`"

HEAT_JSON="`echo $HEAT_JSON|sed s/TESTSTACK/$stackname/g`"


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
[ $? -ne 0 ] && echo "Unable to get token from keystone." 1>&2 && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:$retcode" && exit 1

export OS_TOKEN="$(echo $OS_TOKEN |awk '{print $2}'|sed 's/\r$//')"

#check if stack already exists
curl -X GET -g -k -q -s -L --fail -o /dev/null \
        -H "X-Auth-Token: $OS_TOKEN" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --max-time 10 \
        --user-agent "curl-healthcheck" \
        $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks/$stackname
retcode=$?

#if stack exist delete it
if [ $retcode -eq 0 ]
then
        curl -X DELETE -g -k -q -s -L --fail -o /dev/null \
        -H "X-Auth-Token: $OS_TOKEN" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --max-time 10 \
        --user-agent "curl-healthcheck" \
        $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks/$stackname
        retcode=$?
        [ $retcode -ne 0 ] && echo "Unable to delete stack $stackname." 1>&2 && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:$retcode" && exit 1
        #SECONDS is bash special variable, it counts number of seconds from start of the sript,
        # setting to nonnumeric value will reset SECONDS to 0
        SECONDS=reset
        while [ "$SECONDS" -lt $deletion_timeout ]; 
        do 
                curl -X GET -g -k -q -s -L --fail -o /dev/null \
                        -H "X-Auth-Token: $OS_TOKEN" \
                        -H "Content-Type: application/json" \
                        -H "Accept: application/json" \
                        --max-time 10 \
                        --user-agent "curl-healthcheck" \
                        $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks/$stackname || break
                echo "Deleting stack. Sleeping 5sec."
                sleep 5 
        done
fi

#check if stack still exists
curl -X GET -g -k -q -s -L --fail -o /dev/null \
         -H "X-Auth-Token: $OS_TOKEN" \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         --max-time 10 \
         --user-agent "curl-healthcheck" \
         $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks/$stackname
retcode=$?
[ $retcode -eq 0 ] && echo "Stack $stackname hasn't been deleted, still exists." 1>&2 && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:1" && exit 1

#create stack
curl -X POST -g -k -q -s --fail -o /dev/null \
      -H "X-Auth-Token: $OS_TOKEN" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      --max-time 10 \
      --user-agent "curl-healthcheck" \
      -d "`echo $HEAT_JSON`" \
      $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks 
retcode=$?
[ $retcode -ne 0 ] && echo "Unable to create stack. Please check HEAT_JSON variable." 1>&2 && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:$retcode" && exit 1

#do checks until stack creation
retcode=1
SECONDS=reset
while [ "$SECONDS" -lt $creation_timeout ]; 
do
        STACK_STATUS="`curl -X GET -g -k -q -s -L -o - --fail \
               -H \"X-Auth-Token: $OS_TOKEN\" \
               -H \"Content-Type: application/json\" \
               -H \"Accept: application/json\" \
               --max-time 10 \
               --user-agent \"curl-healthcheck\" \
	       --write-out \"\n\" \
               $HEAT_ENDPOINT/$OS_PROJECT_ID/stacks/$stackname`" 
        STACK_STATUS="`echo $STACK_STATUS|python -m json.tool|grep \\"stack_status\\"|awk -F: '{print $2}'|awk -F\\" '{print $2}'`"
        echo $STACK_STATUS|grep CREATE_COMPLETE &>/dev/null && retcode=0 && break
        echo $STACK_STATUS|grep CREATE_FAILED &>/dev/null && retcode=1 && break
        echo $STACK_STATUS|grep ROLLBACK_COMPLETE &>/dev/null && retcode=2 && break
        echo $STACK_STATUS|grep ROLLBACK_FAILED &>/dev/null && retcode=3 && break
        echo "Stack status $STACK_STATUS. Sleeping 10sec."
        sleep 10
done
[ $retcode -eq 0 ] && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:$retcode" && exit 0
[ $retcode -ne 0 ] && echo "PUTVAL `hostname`/heat/commands-stack interval=60 N:$retcode" && exit 1
