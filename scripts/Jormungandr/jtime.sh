#!/bin/bash

# jtime version 0.1 initial release
#
# by gufmar (edu.clio.one)

# Please donate some (real) ADA to"
# Ae2tdPwUPEZJy2DbueGwkLjCqNcypkj5Aa3waEZdvBKMsNqjNw2kTqPfyhe"
# Thanks in advance!"

NODE_REST_PORT=3100
NODE_REST_URL="http://127.0.0.1:${NODE_REST_PORT}/api"

convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02d:%02d:%02d\n" $h $m $s
}

settings="$(curl -s ${NODE_REST_URL}/v0/settings)"
block0Time=$(echo ${settings} | jq -r .block0Time)
block0Timestamp=$(date -d "${block0Time}" +"%s")

currTimestamp=$(date +"%s")

slotDuration=$(echo ${settings} | jq -r .slotDuration)
slotsPerEpoch=$(echo ${settings} | jq -r .slotsPerEpoch)

echo "block0Timestamp:       ${block0Timestamp}"
echo "currTimestamp:         ${currTimestamp}"

deltaBlock0Seconds=$((currTimestamp - block0Timestamp))

echo "DeltaBlock0Seconds:    ${deltaBlock0Seconds} ($(convertsecs $deltaBlock0Seconds))"

epoch=$((deltaBlock0Seconds / (slotDuration * slotsPerEpoch )))

echo "Epoch:                 ${epoch}"

nextEpochStartTimestamp=$((block0Timestamp + ((epoch +1) * slotDuration * slotsPerEpoch)))

remainingSeconds=$((nextEpochStartTimestamp - currTimestamp))

echo "Seconds to next epoch: ${remainingSeconds}s ($(convertsecs $remainingSeconds))"
