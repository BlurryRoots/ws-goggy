#!/bin/bash

# Run script for 'Theme Hospital' (1207659026)
play () {
	source ${WS_CFG_PATH}/ws-shared	

	local gameroot="/opt/goggy/games/1207659026"
	local internalroot="${gameroot}/payload/Contents/Resources"

	if ! which dosbox > /dev/null; then
		_ws_log error "Could not find dosbox :("
		return -1
	fi

	local usage="usage: $0 <command> [args]"
	usage="${usage}\ncommands:"
	usage="${usage}\n\tsingle"
	usage="${usage}\n\tclient"
	usage="${usage}\n\tserver"

	if (( 1 > $# )); then
		_ws_log error "missing arguments"
		_ws_log error "${usage}"
		return 13
	fi

	pushd "${internalroot}" > /dev/null

	local cmd="${1}"
	case ${cmd} in
		single)
			dosbox \
				-conf game/dosboxTH.conf \
				-conf game/dosboxTH_single.conf
		;;

		client)
			dosbox \
				-conf game/dosboxTH.conf \
				-conf game/dosboxTH_client.conf
		;;

		server)
			dosbox \
				-conf game/dosboxTH.conf \
				-conf game/dosboxTH_server.conf
		;;

		*)
			_ws_log error "unknown command ${1}"
			_ws_log error "${usage}"
			return 13
		;;
	esac
	popd > /dev/null

	return $?
}

play $*
