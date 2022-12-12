#!/bin/bash

home=$(dirname -- "${BASH_SOURCE[0]}")
startDir=$(pwd 2>&1)
source $home\/.zyncconfig
logPath="$home/.zynclog"
folders=""
help=true
setAll=false
while getopts af:s: flag
do
	case "${flag}" in
		a) setAll=true
			help=false;;
		f) folders=${OPTARG} 
			help=false;;
		s) setEnv=true
			help=false
			ZYNC_ACCOUNT=${OPTARG};;
	esac
done

if [ "$setAll" = true ]; then
	folders="$folders/*"
fi

if [ "$help" = true ]; then
	echo "zync v1.0 by Zac"
	echo "a tool to sync your forks main (warning, will hard reset)"
	echo "-a <folder> run on all subfolders"
	echo "-f <folder> run on a select folder"
	echo "-s run to set github account"
	exit
fi

if [ "$setEnv" = true ]; then
	echo "ZYNC_ACCOUNT=$ZYNC_ACCOUNT" > $home\/.zyncconfig
fi

if [ -z "$ZYNC_ACCOUNT" ]; then
	echo "git account for upstream repo must be set"
	exit
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
				cd $startDir
				echo "$dummy" > "$logPath"
				echo "problems encountered, please check .zynclog"
				exit
		else 
			echo "$rebaseLog"
		fi
		cd $startDir
	else 
		echo "not a valid folder"
	fi
done