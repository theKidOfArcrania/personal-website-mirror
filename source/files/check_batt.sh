#!/bin/bash

CRITICAL=10
LOW=25

# State: 1: we were okay, 2: low battery, 3: critical 
STATE=1

while true; do
  BATT=`acpi -b`
  PERC=$(echo $BATT | cut -d "," -f 2 | cut -c 2-3)
  if echo $BATT | grep "Discharging" > /dev/null; then 
    if [ $PERC -le $CRITICAL -a $STATE -lt 3 ]; then
      STATE=3
      notify-send -i error -u critical "BATTERY CRITICAL" \
        "Battery is less than $CRITICAL%."
    elif [ $PERC -le $LOW -a $STATE -lt 2 ]; then
      STATE=2
      notify-send -i error -u critical "BATTERY LOW" "Battery is less than $LOW%."
    fi
  else
    if [ $PERC -le $CRITICAL ]; then
      STATE=3
    elif [ $PERC -le $LOW ]; then
      STATE=2
    else
      STATE=1
    fi
  fi
  sleep 5
done
