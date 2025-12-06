#!/bin/zsh

root="/Users/mohamedaminedhahri/Desktop/Code/Collector/debugging.txt"

# cat $root | grep 'ERR' | awk -F '::' '{print $0}' | column -s '::' -t
cat $root | grep 'DUBUG' | awk -F '::' '/zip/ && /htmlPublishers/ {print $2, $3}' | sort -k 1 | sed 's/.zip /=/g' | column -s '=' -t