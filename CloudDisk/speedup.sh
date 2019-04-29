#!/usr/bin/env bash

base_dir=`dirname $0`
source "$base_dir/utils.sh"
config="$base_dir/config.json"


AppKey=`getSingleJsonValue "$config" "AppKey"`
AppSignature=`getSingleJsonValue "$config" "AppSignature"`
accessToken=`getSingleJsonValue "$config" "accessToken"`
qosClientSn=`getSingleJsonValue "$config" "qosClientSn"`
method=`getSingleJsonValue "$config" "method"`
rate=`getSingleJsonValue "$config" "rate"`
UA=`getSingleJsonValue "$config" "User-Agent"`
extra_header="User-Agent:$UA"


HOST="http://api.cloud.189.cn"
LOGIN_URL="/login4MergedClient.action"
ACCESS_URL="/speed/startSpeedV2.action"
count=0
echo "*******************************************"
while :
do
    count=$((count+1))
    echo "Sending heart_beat package <$count>"
    split="~"
    headers_string="AppKey:$AppKey"${split}"AppSignature:$AppSignature"${split}"$extra_header"
    headers=`formatHeaderString "$split" "$headers_string"`
    login_result="`post \"$HOST$LOGIN_URL?accessToken=$accessToken\" \"$headers\"`"
    session_key=`echo "$login_result" | grep -Eo "sessionKey>.*</sessionKey" | sed 's/<\/sessionKey//' | sed 's/sessionKey>//'`
    session_secret=`echo "$login_result" | grep -Eo "sessionSecret>.*</sessionSecret" | sed 's/sessionSecret>//' | sed 's/<\/sessionSecret//'`
    date=`env LANG=C.UTF-8 date -u '+%a, %d %b %Y %T GMT'`
    data="SessionKey=$session_key&Operate=$method&RequestURI=$ACCESS_URL&Date=$date"
    key="$session_secret"
    signature=`hashHmac "sha1" "$data" "$key"`
    split="~"
    headers_string="SessionKey:$session_key"${split}"Signature:$signature"${split}"Date:$date"${split}"$extra_header"
    headers=`formatHeaderString "$split" "$headers_string"`
    for i in 1 2 3
    do
        result=`get "$HOST$ACCESS_URL?qosClientSn=$qosClientSn" "$headers"`
    done
    echo "heart_beat:<signature:$signature>"
    echo "date:<$date>"
    echo -e "response:\n$result"
    [[ "`echo ${result} | grep dialAccount`" != "" ]] &&  hint="succeeded" || hint="failed"
    echo "Sending heart_beat package <$count> $hint"
    echo "*******************************************"
    sleep ${rate}
done
