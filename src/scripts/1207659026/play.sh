#!/bin/bash
# (c) 2023 Sven Freiberg

# Pull in logging helper.
source "$(dirname "$(realpath $(which goggy))")/logging.sh"

# Run script for 'Theme Hospital' (1207659026)
play () {
	local goggyroot="/opt/goggy"
	# Read goggyroot if available.
	if [ -f "${goggyconfig}" ]; then
		_goggy_log verbose "Reading game root from config ..."
		goggyroot=$(awk -F "=" '/root/ {print $2}' "${goggyconfig}")
	fi

	local gameid=1207659026
	local gameroot="${goggyroot}/games/${gameid}"
	local internalroot="${gameroot}/payload/Contents/Resources"

	_goggy_log verbose "Game root at: '${gameroot}'"

	if ! which dosbox > /dev/null; then
		_goggy_log error "Could not find dosbox :("
		return -1
	fi

	local usage="USAGE: goggy play ${gameid} <command>"
	usage="${usage}\ncommand:"
	usage="${usage}\n\tsingle"
	usage="${usage}\n\tclient"
	usage="${usage}\n\tserver"
	usage="${usage}\n\thelp"

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

		help)
			printf "%b" "${usage}"

			return 0
		;;

		"")
			_goggy_log error "Empty command."

			printf "%b" "${usage}"

			return 13
		;;			

		*)
			_goggy_log error "unknown command ${1}"

			printf "%b" "${usage}"

			return 13
		;;
	esac
	popd > /dev/null

	return $?
}

play $*
