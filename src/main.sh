#!/bin/bash

goggy () {
	source ${WS_CFG_PATH}/ws-shared

	local cacheroot="/tmp/pkger"
	local goggyroot="/opt/goggy"
	local self="$(basename $0)"

	mkdir -p ${cacheroot}

	# utility script to unpack macos pkg files.
	case $1 in
		i|install)
			echo "Needs administrator rights ..."
			sudo mkdir -p ${goggyroot}/{cache,games,scripts,installed}
			sudo chown -R sol:sol ${goggyroot}
		;;

		u|uninstall)
			echo "not implemented yet :/"
			return 13
		;;

		l|list)
			for gameinfo in $(ls "${goggyroot}/installed"); do
				local name=$(cat "${goggyroot}/installed/${gameinfo}" | jq .name)
				local gameid=$(cat ${goggyroot}/installed/${gameinfo} | jq .gameId)
				echo "${name} (${gameid})"
			done
		;;

		n|unpack)
			if [ $# -lt 3 ]; then
				echo "usage: ${self} unpack <*.pkg> <game-name>"
				return 13
			fi

			local pkg="$(realpath -s $2)"
			if [ ! -e "${pkg}" ]; then
				echo "Could not find ${pkg}!"
				return 13
			fi

			local out=$(realpath -s "${goggyroot}/games/$3")
			echo "Creating game path at '${out}' ..."
			mkdir -p "${out}"

			local ts=$(python3 -c "import time; print(time.time())")
			local tmppath="/tmp/goggy/$ts"
			mkdir -p "${tmppath}"; pushd "${tmppath}" > /dev/null
				echo "Extracting '${pkg}' ..."
				7z x "$pkg" -o"${tmppath}" > /dev/null
				echo "Temp Result:"
				ls -lav .
				local datapk="package.pkg/Scripts"
				cat "${datapk}" | gunzip -dc | cpio -i -D "${out}"
			popd > /dev/null

			rm -rf "${tmppath}"


		;;

		d|discard)
			echo "discarding package ..."
			echo "not implemented yet :/"

			return 13
		;;

		p|play)
			shift
			if ((  2 > $# )); then
				local usage="usage: ${self} play [id] [mode]"
				printf "%b" "${usage}"

				return 13
			fi

			local gameid="$1"
			local inforoot="${goggyroot}/installed/${gameid}.info"
			if [ ! -e ${inforoot} ]; then
				_ws_log error "Game with ID ${gameid} is not installed."
				return 13
			fi

			local mode="$2"
			local gameroot="${goggyroot}/scripts/${gameid}"
			if [ ! -e ${gameroot} ]; then
				_ws_log error "could not find game root for id ${gameid}!"
				return 13
			fi

			local name=$(cat "${goggyroot}/installed/${gameid}.info" | jq .name)
			echo "Playing $name ($gameid) ..."
			pushd ${gameroot} > /dev/null
				./play.sh ${mode}
			popd > /dev/null
		;;

		c|clear-cache)
			rm -rf ${cacheroot}
		;;

		v|version)
			echo "1.6.18"
		;;

		*)
			local usage="USAGE: ${self} <options> [command] ..."
			usage="${usage}\ncommands:"
			usage="${usage}\n\tinstall"
			usage="${usage}\n\tuninstall"
			usage="${usage}\n\tlist"
			usage="${usage}\n\tunpack"
			usage="${usage}\n\tdiscard"
			usage="${usage}\n\tplay"
			usage="${usage}\n\tclear-cache"
			usage="${usage}\n\tversion"

			printf "%b" "${usage}"

			return 13
		;;
	esac

	return $?
}

goggy $*
