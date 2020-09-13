#!/bin/bash
# ANSIBLE GATEWAY

case "$1" in
	"--init" )
		# START DANTED AS SERVICE
		service ssh start;
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
			srv=`nslookup -querytype=srv -nofail -retry=2 "$GATEWAY_REMOTE_HOST." | grep -w "^$GATEWAY_REMOTE_HOST" | sort -k 5 -r | awk '{ print $7 ":" $6 }'`;
			srv_host="${srv%:*}";
			srv_port="${srv#*:}";
		else
			echo "ERROR: Variable GATEWAY_REMOTE_HOST not defined !" >&2;
			exit 1;
		fi;

		# exec now
		export GATEWAY_PORT="$srv_port";
		exec ssh -o "RemoteForward=$GATEWAY_PORT" -R "$(($GATEWAY_PORT+1)):localhost:1080" "$srv_host@$GATEWAY_REMOTE_HOST" -- "$@";
		;;
	* )
		echo "UNSUPPORTED COMMAND: $1" >&2;
		exit 1;
		;;
esac;
