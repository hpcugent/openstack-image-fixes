#!/bin/bash

export rcfile="/opt/configrc"

source $rcfile

[ -z ${HOSTNAME_TO_RUN+x} ] && echo "Variable HOSTNAME_TO_RUN is unset." 1>&2 && exit 1
[ -z ${SSL_ENDPOINTS_TO_CHECK+x} ] && echo "Variable SSL_ENDPOINTS_TO_CHECK is unset." 1>&2 && exit 1
[ -z ${SSL_EXPIRATION_IN_NUMBER_OF_SECONDS_CHECK+x} ] && echo "Variable SSL_EXPIRATION_IN_NUMBER_OF_SECONDS_CHECK is unset." 1>&2 && exit 1

#if not running from correct host exit the script
hostname|grep "$HOSTNAME_TO_RUN" &>/dev/null || exit 1

retcode=0
for endpoint in $SSL_ENDPOINTS_TO_CHECK
do
        echo | openssl s_client -connect "$endpoint" 2>/dev/null | openssl x509 -enddate -noout -checkend "$SSL_EXPIRATION_IN_NUMBER_OF_SECONDS_CHECK" &>/dev/null
        retcode="$?"
        echo "PUTVAL $(hostname)/SSL_expiration_check/commands-SSL_expiration_$endpoint interval=900 N:$retcode"
done
