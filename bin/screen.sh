#!/bin/sh
mode=${1:-rails}
session=${2:-rails}
echo $mode
echo $session
case $mode in
	init)
		# http://stackoverflow.com/questions/2156290/how-do-you-script-gnu-screen-from-within-a-screen-session-to-open-new-windows-and
		sleep 0.2
		screen -d
		sh
		#sh -c $0 rails $session
		;;
	rails)
		#[ $session = "rails" ] && session=$(screen -X sessionname) ]
		/opt/local/bin/screen -x $session -X screen -t irb rails c
		/opt/local/bin/screen -x $session -X screen -t sql rails db
		/opt/local/bin/screen -x $session -X screen
		;;
	*)
		;;
esac
