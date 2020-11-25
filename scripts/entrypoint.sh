#!/bin/bash
# ANSIBLE GATEWAY

function __dns_srv_resolve() {
	nslookup -querytype=srv -nofail -retry=2 "$1." | grep -w "^$1" | sort -k 5 -r | awk '{ print $7 ":" $6 }';
}

case "$1" in
	"--init" )
		tail -f /dev/null;
		;;
	"--init-danted" )
		# START DANTED AS SERVICE
		service danted start;
		tail -f /dev/null;
		;;
	"exec" )
		exec "$@";
		;;
	"ansible" | "ansible-playbook" | "ansiblegw" )
		if [ -z "$GATEWAY_REMOTE_HOST" ];
		then
			echo "ERROR: Variable GATEWAY_REMOTE_HOST not defined !" >&2;
			exit 1;
		fi;

		# discover our gateway port (from SRV record)
		srv_port="";
		if [ -z "$GATEWAY_USER" ];
		then
			prefix="_socks._tcp";
			srv=`__dns_srv_resolve "$prefix.$GATEWAY_REMOTE_HOST" | grep -m 1 "^$prefix"`;
			srv_user="${srv%:*}";
			srv_port="${srv#*:}";

			if [ -z "$srv" -o -z "$srv_user" -o -z "$srv_port" ];
			then
				echo "WARNING: Failed to discover forward configuration !" >&2;
			fi;

			export GATEWAY_USER="$srv_user";
			export GATEWAY_PORT="$srv_port";
		fi;

		# process hook
		declare -a GATEWAY_ARGS;
		if [ -x "/config/ansible.hook.sh" ];
		then
			source /config/ansible.hook.sh;
		else
			if [ -n "$GATEWAY_PORT" ];
			then
				GATEWAY_ARGS+=(-o "RemoteForward=$GATEWAY_PORT");
			fi;
		fi;

		# check variables
		if [ -z "$GATEWAY_USER" ];
		then
			echo "ERROR: Variable GATEWAY_USER not defined !" >&2;
			exit 1;
		fi;

		# exec now
		exec ${GATEWAY_SSH:-ssh} "${GATEWAY_ARGS[@]}" "$GATEWAY_USER@$GATEWAY_REMOTE_HOST" -- "$@";
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
