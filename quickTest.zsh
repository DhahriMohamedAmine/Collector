#!/bin/zsh

zmodload zsh/datetime
typeset -F TIMER=0.0       # Floating point total time
typeset -F _TIMER_START=0.0  # Floating point start time
function start_timer() { _TIMER_START=$EPOCHREALTIME }
function end_timer() {
    # Only run if the timer was actually started
    if (( _TIMER_START > 0.0 )); then
        local end_time=$EPOCHREALTIME
        local duration=$(($end_time - $_TIMER_START))
        TIMER=$(($TIMER + $duration))
        _TIMER_START=0.0 # Reset start time
    fi
}


typeset -F TOTAL_TIMER=$EPOCHREALTIME


debug=$(echo "Total:" $TIMER
echo "Count:" $process_count
echo "Average:" $(( $TIMER / $process_count ))
local perc=$(( ($TIMER / ($EPOCHREALTIME - $TOTAL_TIMER)) * 100 ))
perc=$(awk -v val="$perc" 'BEGIN { printf "%.2f", val }')
echo "perc.:" "$perc%")

echo
echo $debug | column -t