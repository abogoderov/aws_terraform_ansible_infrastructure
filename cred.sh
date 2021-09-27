#!/bin/bash	
echo Enter/paste your AWS Access key:
read -s aws_ak
echo Enter/paste your AWS Secret key: 
read -s aws_sk

if [ -e $HOME/.aws/credentials ]
then
	printf "You already have AWS credentials file, try using export to add your AWS keys in current terminal session or edit .aws/credentials manualy.\nAdding new keys to your current .aws/credentials will be featured in next versions\n"
else 
	if [ -e $HOME/.aws ]
	then
		cd $HOME/.aws
	else
	mkdir $HOME/.aws/ && cd $HOME/.aws
	fi
	touch credentials
	printf "[default]\naws_access_key_id=$aws_ak\naws_secret_access_key=$aws_sk" >> $HOME/.aws/credentials
fi