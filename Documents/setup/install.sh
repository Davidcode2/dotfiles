#!/bin/bash

echo "starting installation script"

while read line;
do 
	yay -S $line --noconfirm --needed --quiet
done < packages1.txt

yay -Syu
