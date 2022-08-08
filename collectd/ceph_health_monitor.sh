#!/bin/bash

export rcfile="/opt/configrc"

source $rcfile

[ -z ${HOSTNAME_TO_RUN+x} ] && echo "Variable HOSTNAME_TO_RUN is unset." 1>&2 && exit 1
[ -z ${CEPH_DASHBOARD_USER+x} ] && echo "Variable CEPH_DASHBOARD_USER is unset." 1>&2 && exit 1
[ -z ${CEPH_DASHBOARD_PASS+x} ] && echo "Variable CEPH_DASHBOARD_PASS is unset." 1>&2 && exit 1
[ -z ${CEPH_DASHBOARD_IP_PORT+x} ] && echo "Variable CEPH_DASHBOARD_IP_PORT is unset." 1>&2 && exit 1

#if not running from correct host exit the script
hostname|grep "$HOSTNAME_TO_RUN" &>/dev/null || exit 1

TOKEN="`curl -s -X POST \"http://$CEPH_DASHBOARD_IP_PORT/api/auth\" -H  \"Accept: application/vnd.ceph.api.v1.0+json\" -H  \"Content-Type: application/json\" -d \"{\\"username\\": \\"$CEPH_DASHBOARD_USER\\", \\"password\\": \\"$CEPH_DASHBOARD_PASS\\"}\"|python3 -m json.tool|grep '"token":'|cut -d\"\\"\" -f4`"

curl -s -X GET "http://$CEPH_DASHBOARD_IP_PORT/api/health/minimal" -H  "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"|grep "HEALTH_OK" &>/dev/null
retcode=$?

echo "PUTVAL `hostname`/ceph_health/commands-health_status interval=900 N:$retcode"
