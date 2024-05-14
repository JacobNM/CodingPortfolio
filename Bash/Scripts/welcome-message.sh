#!/bin/bash
#
# This script produces a dynamic welcome message
# it should look like
#   Welcome to planet hostname, title name!

###############
# Variables   #
###############
myname=$USER
hostname=$(hostname)
dayOfWeek=$(date +%A)
timeNowLocal=$(date +"%H:%M %p")

## Creating a dynamic title
title="$dayOfWeek"

if [[ "${title}" == "Sunday" ]]; then
    title="Sir"
elif [[ "${title}" == "Monday" ]]; then
    title="Commander"
elif [[ "${title}" == "Tuesday" ]]; then
    title="Captain"
elif [[ "${title}" == "Wednesday" ]]; then
    title="Master"
elif [[ "${title}" == "Thursday" ]]; then
    title="Chief"
elif [[ "${title}" == "Friday" ]]; then
    title="Colonel"
elif [[ "${title}" == "Saturday" ]]; then
    title="Private"
fi

###############
# Main        #
###############
cat <<EOF

Welcome to planet $hostname, "$title $myname!"
it is $dayOfWeek at $timeNowLocal
EOF
