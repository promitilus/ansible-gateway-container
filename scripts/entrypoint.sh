#!/bin/bash
# ANSIBLE GATEWAY

case "$1" in
	"--init" )
		# START DANTED AS SERVICE
		service danted start;
		tail -f /dev/null;
		;;
	"exec" )
		exec "$@";
		;;
	"ansible" | "ansible-playbook" )
		# discover our gateway port (from SRV record)
		srv_port="";
		if [ -n "$GATEWAY_REMOTE_HOST" ];
		then
			prefix="_socks._tcp";
			srv=`nslookup -querytype=srv -nofail -retry=2 "$prefix.$GATEWAY_REMOTE_HOST." | grep -w "^$prefix.$GATEWAY_REMOTE_HOST" | sort -k 5 -r | awk '{ print $7 ":" $6 }' | grep -m 1 "^$prefix"`;
			srv_user="${srv%:*}";
			srv_port="${srv#*:}";

			if [ -z "$srv" -o -z "$srv_user" -o -z "$srv_port" ];
			then
				echo "ERROR: Failed to discover forward configuration !" >&2;
				exit 1;
			fi;
		else
			echo "ERROR: Variable GATEWAY_REMOTE_HOST not defined !" >&2;
			exit 1;
		fi;

		# exec now
		export GATEWAY_PORT="$srv_port";
		exec ssh -o "RemoteForward=$GATEWAY_PORT" -R "$(($GATEWAY_PORT+1)):localhost:1080" "$srv_user@$GATEWAY_REMOTE_HOST" -- "$@";
		;;
	"" )
		echo "COMMAND MISSING !" >&2;
		exit 1;
		;;		
	* )
		echo "UNSUPPORTED COMMAND: $1" >&2;
		exit 1;
		;;
esac;
