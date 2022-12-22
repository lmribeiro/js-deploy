#!/bin/bash

mkdir -p /root/.ssh
ssh-keyscan -H "$2" >> /root/.ssh/known_hosts

if [ -z "$DEPLOY_KEY" ];
then
	echo $'\n' "------ DEPLOY KEY NOT SET YET! ----------------" $'\n'
	exit 1
else
	printf '%b\n' "$DEPLOY_KEY" > /root/.ssh/id_rsa
	chmod 400 /root/.ssh/id_rsa

	echo $'\n' "------ CONFIG SUCCESSFUL! ---------------------" $'\n'
fi

echo $'\n' "------ SYNC START -------------------------" $'\n'

rsync --progress -avzh \
	--exclude='.git/' \
	--exclude='.git*' \
	--exclude='.editorconfig' \
	--exclude='.styleci.yml' \
	--exclude='.idea/' \
	--exclude='Dockerfile' \
	--exclude='readme.md' \
	--exclude='README.md' \
	-e "ssh -i /root/.ssh/id_rsa" \
	--rsync-path="sudo rsync" . $1@$2:$3

if [ $? -eq 0 ]
then
	echo $'\n' "------ SYNC SUCCESSFUL! -----------------------" $'\n'
	echo $'\n' "------ GENERATING VERSION FILES ---------------" $'\n'

  echo $'' "- Delete old files " $''
  rm js/app_*
  rm js/index_*

  echo $'' "- Generate new files " $''
  timestamp=$(date +%s)
  cp js/app.js js/app_$timestamp.js
  cp js/index.js js/index_$timestamp.js

  echo $'' "- Replace imports " $''
  app=app_$timestamp.js
  index=index_$timestamp.js

  sed -i.back 's/js\/app.js/js\/'$app'/g' 'index.html'
  sed -i.back 's/js\/index.js/js\/'$index'/g' 'index.html'

  echo $'' "- Delete back file " $''
  rm index.html.back

	echo $'\n' "------ RELOADING PERMISSION -------------------" $'\n'

	ssh -i /root/.ssh/id_rsa -tt $1@$2 "sudo chown -R $4:$4 $3"

	echo $'\n' "------ CONGRATS! DEPLOY SUCCESSFUL!!! ---------" $'\n'
	exit 0
else
	echo $'\n' "------ DEPLOY FAILED! -------------------------" $'\n'
	exit 1
fi
