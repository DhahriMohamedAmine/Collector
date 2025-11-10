#!/bin/zsh

text='partner
htmlPublishers name
offer match
offer folder
offer name
SIZE
partner name
htmlPublishers folder
offer
partner folder
FORMAT
partner match
htmlPublishers match
MARKETS
EXTENSION
NAME
INDEX
htmlPublishers'

# L=$(echo "$TT" | wc -l -w | sort -n)

text=$(print -l ${(on)"${(f)text}"} | awk '{ print NF, $0 }' | sort -rn | cut -d' ' -f2-)
echo ${text// /.}