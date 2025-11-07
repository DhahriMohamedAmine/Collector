#!/bin/zsh

typeset -A array
array[A]=a
array["HELLO THERE"]=a

mm="HELLO THERE"

echo "${array["$mm"]}"