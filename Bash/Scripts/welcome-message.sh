#!/bin/bash
#
# This script produces a dynamic welcome message
# it should look like
#   Welcome to planet hostname, title name!

# Task 1: Use the variable $USER instead of the myname variable to get your name
# Task 2: Dynamically generate the value for your hostname variable using the hostname command - e.g. $(hostname)
# Task 3: Add the time and day of the week to the welcome message using the format shown below
#   Use a format like this:
#   It is weekday at HH:MM AM.
# Task 4: Set the title using the day of the week
#   e.g. On Monday it might be Optimist, Tuesday might be Realist, Wednesday might be Pessimist, etc.
#   You will need multiple tests to set a title
#   Invent your own titles, do not use the ones from this example

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
