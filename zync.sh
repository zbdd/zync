#!/bin/bash

#version 1.2.1
home=$(dirname -- "${BASH_SOURCE[0]}")
startDir=$(pwd )
source $home\/.zyncconfig
logPath="$home/.zynclog"
folders=""
help=true
setAll=false
while getopts af:qs: flag
do
	case "${flag}" in
		a) setAll=true
			help=false
			echo "checking all subfolders";;
		f) folders=${OPTARG} 
			help=false;;
		q) exec 1>>"$logPath" 
			help=false;;
		s) setEnv=true
			help=false
			echo "setting account"
			ZYNC_ACCOUNT=${OPTARG};;
	esac
done

if [ "$setAll" = true ]; then
	folders="$folders/*"
fi

if [ "$help" = true ]; then
	echo "zync v1.2.1 by Zac"
	echo "a tool to sync your forks main (warning, will hard reset)"
	echo "-a <folder> run on all subfolders of folder"
	echo "-f <folder> run on a select folder"
	echo "-q silent-mode, send all output to logfile" 
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
		echo "$i git sync started"
		dummy+=$(git checkout main  )
		if [[ "$dummy" =~ "not a git repository" ]]; then
			continue
		fi
		dummy+=$(git reset --hard )
		remote="git@github.com:$ZYNC_ACCOUNT/$i.git"
	  dummy+=$(git remote add origin-upstream $remote )
	  dummy+=$(git fetch origin-upstream  )
	  hasChanges=$(git pull origin-upstream main )
	  if [[ "$hasChanges" =~ "Already up to date" ]];
	  	then echo "up to date, skipping"
	  		continue;
	  fi
	  dummy+=$hasChanges
		dummy+=$(git checkout origin-upstream/main )
		dummy+=$(git checkout main )
		rebaseLog=$(git rebase origin-upstream/main  )
		dummy+="$rebaseLog"
		dummy+=$(git push )
		if [[ "$dummy" =~ "fatal" ]];
			then 
				cd $startDir
				echo "$dummy"
				echo "$i: problems encountered"
				exit
		else 
				echo "$i - $rebaseLog"
		fi
		cd $startDir
	else 
		echo "not a valid folder"
	fi
done

echo "done"