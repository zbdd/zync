#!/bin/bash

source .zyncconfig
home=$(pwd)
logPath="$(pwd)/.zynclog"
folders=""
help=true
while getopts af:s: flag
do
	case "${flag}" in
		a) folders=*
			help=false;;
		f) folders=${OPTARG} 
			help=false;;
		s) setEnv=true
			help=false
			ZYNC_ACCOUNT=${OPTARG};;
	esac
done

if [ "$help" = true ]; then
	echo "zync v1.0 by Zac"
	echo "a tool to sync your forks main (warning, will hard reset)"
	echo "-a run on all subfolders"
	echo "-f run on a select folder"
	echo "-s run to set github account"
	exit
fi

if [ "$setEnv" = true ]; then
	echo "ZYNC_ACCOUNT=$ZYNC_ACCOUNT" > .zyncconfig
fi

if [ "$folders" = "" ]; then
	exit
fi

for i in $folders
do
	if [ -d "$i" ]; then
		cd "$i"
		i=$(echo $i | sed "s/.*\///")
		echo "syncing github repo: $i"
		dummy=$(git checkout main 2>&1 )
		dummy+=$(git reset --hard 2>&1)
		remote="git@github.com:$ZYNC_ACCOUNT/$i.git"
	  	dummy+=$(git remote add origin-upstream $remote 2>&1)
	  	echo "fetching upstream"
	  	dummy+=$(git fetch origin-upstream  2>&1)
		dummy+=$(git checkout origin-upstream/main 2>&1)
		dummy+=$(git checkout main 2>&1)
		rebaseLog=$(git rebase origin-upstream/main  2>&1)
		dumm+="$rebaseLog"
		dummy+=$(git push 2>&1)
		if [[ "$dummy" =~ "fatal" ]];
			then 
				cd $home
				dummy+=$(git rebase --abort)
				echo "$dummy" > "$logPath"
				echo "problems encountered, please check .zynclog"
				exit
		else 
			echo "$rebaseLog"
		fi
		cd $home
	else 
		echo "not a valid folder"
	fi
done