#!/bin/bash

echo "starting installation script"

package=$(./packages.txt)
while read package;
do 
	echo "yay -S $package --noconfirm --needed --quiet";
done
echo "yay -Syu"
