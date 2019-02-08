#!/bin/bash

function usage() {
  echo -e "Usage:"
  echo -e "./pipe_freeze_alert.sh temperature"
  echo
  echo -e "Send Slack alert if the temperature over the next 14 days dips below the value given."
}

if [ ! -f /usr/bin/slacktee.sh ]; then
  echo "Slacktee.sh is missing!"
  exit 1
fi
FORECAST_URL=$(curl https://api.weather.gov/points/40.0004,-74.9973 2> /dev/null | jq -r '.properties.forecast')
FORECAST_JSON=$(curl $FORECAST_URL 2> /dev/null)
MAX_DAYS=13

# https://unix.stackexchange.com/questions/13731/is-there-a-way-to-get-the-min-max-median-and-average-of-a-list-of-numbers-in
MIN=$(for day in $(seq 1 $MAX_DAYS); do
    echo $FORECAST_JSON | jq -r --arg day $day '.properties.periods[$day | tonumber].temperature'
done | jq -s min)

if [ -z "$1" ]; then
  usage
  exit 1
fi

if [ "$MIN" -le "$1" ]; then
  echo "PIPE FREEZE WARNING!" | slacktee.sh -a "danger" -e "Date and Time" "$(date)" -s "Low Temp" "$MIN" -c "@daniel"
fi
