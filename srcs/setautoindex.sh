#!/bin/bash

if [[ $1 == "on" ]]
then
	sed -i $'s/\t\tautoindex off/\t\tautoindex on/' /etc/nginx/sites-available/default
	service nginx reload
elif [[ $1 == "off" ]]
then
	sed -i $'s/\t\tautoindex on/\t\tautoindex off/' /etc/nginx/sites-available/default
	service nginx reload
else
	echo "unknown option"
fi