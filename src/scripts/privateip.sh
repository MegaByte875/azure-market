#!/bin/bash

cd /tmp
touch privateIP.txt

echo "$1" > privateIP.txt
echo "$2" >> privateIP.txt
echo "$3" >> privateIP.txt