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
			_ws_log error "not implemented yet :/"
			return 13
		;;

		l|list)
			for gameinfo in $(ls "${goggyroot}/installed"); do
				local name=$(cat "${goggyroot}/installed/${gameinfo}" | jq .name)
				local gameid=$(cat ${goggyroot}/installed/${gameinfo} | jq .gameId | tr -dc '0-9')
				echo "${name} (${gameid})"
			done
		;;

		n|unpack)
			if [ $# -lt 2 ]; then
				echo "usage: ${self} unpack [*.pkg]"
				return 13
			fi

			local pkgsrc="$2"
			local pkg="$(realpath -s ${pkgsrc})"
			if [ ! -e "${pkg}" ]; then
				echo "Could not find ${pkg}!"
				return 13
			fi

			local ts=$(python3 -c "import time; print(time.time())")
			local tmppath="/tmp/goggy/$ts"
			mkdir -p "${tmppath}"; pushd "${tmppath}" > /dev/null
				echo "Extracting '${pkg}' ..."
				7z x "$pkg" -o"${tmppath}" > /dev/null
				echo "Temp Result:"
				ls -lav .
				
				local datapk="package.pkg/Scripts"
				local rawpak="unpacked"
				mkdir -p ${rawpak}
				cat "${datapk}" | gunzip -dc | cpio -i -D "${rawpak}"

				echo "Unpacked:"
				ls -lav "${rawpak}"

				local gameinfosrc=$(find "${rawpak}/payload/Contents" -iname "*.info" | head -n 1)
				local gameinfoid=$(basename -s .info "${gameinfosrc/goggame-/}")
				#gameinfoid=${gameinfoid/goggame-/}
				echo "Found gameinfo at '${gameinfosrc}' with id ${gameinfoid}."

				local out=$(realpath -s "${goggyroot}/games/${gameinfoid}")
				if [ -e "${out}" ]; then
					_ws_log error "Game path already present at '${out}'."

					return 13
				fi

				echo "Creating game path at '${out}' ..."
				mkdir "${out}"

				echo "Copying game data ..."
				cp -Ra "${rawpak}"/* "${out}"

				local gameinfolive=$(find "${out}/payload/Contents" -iname "*.info" | head -n 1)
				echo "Linking game info ..."
				if ! ln -s \
					"${gameinfolive}" \
					"${goggyroot}/installed/${gameinfoid}.info"
				then
					_ws_log error "Gameinfo already present." \
						"Seems like fragments from a previous installation." \
						"Try removing them from '${goggyroot}' and try again."
				fi
				echo "Game '${gameinfoid}' ready for play."
			popd > /dev/null

			rm -rf "${tmppath}"
		;;

		d|discard)
			echo "discarding package ..."
			_ws_log error "not implemented yet :/"

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
