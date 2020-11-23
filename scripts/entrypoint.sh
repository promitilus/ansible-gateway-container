#!/bin/bash
# ANSIBLE GATEWAY

function __dns_srv_resolve() {
	nslookup -querytype=srv -nofail -retry=2 "$1." | grep -w "^$1" | sort -k 5 -r | awk '{ print $7 ":" $6 }';
}

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
			srv=`__dns_srv_resolve "$prefix.$GATEWAY_REMOTE_HOST" | grep -m 1 "^$prefix"`;
			srv_user="${srv%:*}";
			srv_port="${srv#*:}";

			if [ -z "$srv" -o -z "$srv_user" -o -z "$srv_port" ];
			then
				echo "WARNING: Failed to discover forward configuration !" >&2;
			fi;
		else
			echo "ERROR: Variable GATEWAY_REMOTE_HOST not defined !" >&2;
			exit 1;
		fi;

		# vars
		export GATEWAY_USER="$srv_user";
		export GATEWAY_PORT="$srv_port";

		# process hook
		if [ -x "/config/ansible.hook.sh" ];
		then
			source /config/ansible.hook.sh;
		fi;

		# exec now
		exec ${GATEWAY_SSH:-ssh} -o "RemoteForward=$GATEWAY_PORT" -R "$(($GATEWAY_PORT+1)):localhost:1080" "$GATEWAY_USER@$GATEWAY_REMOTE_HOST" -- "$@";
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
