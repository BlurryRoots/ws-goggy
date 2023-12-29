#!/bin/bash
# (c) 2023 Sven Freiberg

# Setup log level constants.
_GOGGY_LOG_VERBOSE=3
_GOGGY_LOG_INFO=2
_GOGGY_LOG_WARNING=1
_GOGGY_LOG_ERROR=0

# Setup log level usage.
_GOGGY_LOG_LVL=$_GOGGY_LOG_INFO
# Setup log level level lookup by name.
declare -A _GOGGY_LVLS=( ["verbose"]=$_GOGGY_LOG_VERBOSE \
	["info"]=$_GOGGY_LOG_INFO \
	["warning"]=$_GOGGY_LOG_WARNING \
	["error"]=$_GOGGY_LOG_ERROR \
)

# Define logging helper function.
_goggy_log () {
	local lvl=${1}

	local lvln=${_GOGGY_LVLS[${lvl}]}
	if (( ${lvln} <= $_GOGGY_LOG_LVL )); then
		echo "log(${lvl}): ${@:2}" >&2
	fi
}

# Define main CLI tool function.
goggy () {
	# .
	local dependent_tools=(jq python3 7z gunzip cpio)
	local cacheroot="$(mktemp).goggy"
	local goggyroot="/opt/goggy"
	local goggyconfig="${HOME}/.config/goggy/setup.cfg"
	local self="$(basename $0)"
	local cmd="${1}"

	# Setup cacheroot for this call.
	_goggy_log verbose "Setting up temporary cache directory  ..."
	mkdir -p "${cacheroot}"

	# Read goggyroot if available.
	if [ -f "${goggyconfig}" ]; then
		_goggy_log verbose "Reading root from config ..."
		goggyroot=$(awk -F "=" '/root/ {print $2}' "${goggyconfig}")
	fi

	# Check if all used tools are available.
	for tool in ${dependent_tools[@]}; do
		if ! which ${tool}; then
			_goggy_log error "Missing '${tool}'. Aborting."

			return 13
		fi
	done

	# utility script to unpack macos pkg files.
	case ${cmd} in
		s|setup)
			shift

			local username=$(whoami) # $(who -s | awk '{ print $1 }')
			if [ -e "${goggyroot}" ]; then
				_goggy_log error "Found goggy directory at '${goggyroot}'." \
					             "Already installed?"

				return 13
			fi

			while getopts d: arg; do
				case ${arg} in
					d)
						goggyroot="${OPTARG}"
						_goggy_log verbose "Chaning root directory to '${goggyroot}'."
						;;

					:)
					  _goggy_log error "Option -${OPTARG} requires an argument."

					  return 13
					  ;;

					\?|*)
					  _goggy_log error "Invalid option: -${OPTARG}."

					  return 13
					  ;;
				esac
			done
			shift $(( OPTIND - 1 ))
			local positionalargs=( "$@" )

			mkdir -p "$(dirname "${goggyconfig}")"
			if ! [ -f "${goggyconfig}" ]; then
				touch "${goggyconfig}"
				echo "root=${goggyroot}" >> "${goggyconfig}"
			else
				if ! sed -i -e "s/root=*/root=${goggyroot}/g" "${goggyconfig}"; then
					_goggy_log error "Could not update config file!"

					return 13
				fi
			fi

			_goggy_log info "Setting up directories for '${username}'. Needs administrator rights."
			sudo mkdir -p "${goggyroot}"/{cache,games,installed}
			_goggy_log info "Ensuring directory ownership ..."
			sudo chown -R ${username}:${username} "${goggyroot}"
			_goggy_log info "Linking game scripts ..."
			ln -s "$(dirname "$0")/scripts" "${goggyroot}"

			echo "Done, goggy is ready at '${goggyroot}'."
			return 0
		;;

		p|purge)
			if ! [ -e "${goggyroot}" ]; then
				_goggy_log error "Could not find goggy root directory."

				return 13
			fi

			local retainconfig=0
			shift
			while getopts R arg; do
				case ${arg} in
					R)
						retainconfig=1
						_goggy_log verbose "Retaining config file."
						;;

					:)
					  _goggy_log error "Option -${OPTARG} requires an argument."

					  return 13
					  ;;

					\?|*)
					  _goggy_log error "Invalid option: -${OPTARG}."

					  return 13
					  ;;
				esac
			done
			shift $(( OPTIND - 1 ))
			local positionalargs=( "$@" )

			local goggysize=$(du -sch "${goggyroot}" \
				| tail -n 1 \
				| awk '{ print $1 }' \
			)

			# Thanks https://stackoverflow.com/a/1885534 for the inspiration.
			_goggy_log warning "About to delete all goggy files" \
							   "(including staged and cached games) totalling '${goggysize}'." \
							   "Needs administrator rights."
			_goggy_log warning "Proceed? ((y)es / (n)o)"
			local rval=13
			read REPLY
			if [[ ${REPLY} =~ ^[Yy]$ ]]; then
				_goggy_log info "Removing goggy (${goggysize}) ..."
				sudo rm -rf "${goggyroot}"
				rval=$?
				if [[ 0 = ${rval} ]]; then
					_goggy_log info "Removed successfully."
				else
					_goggy_log error "Could not remove. (${rval})"
				fi

				if [[ 0 = ${retainconfig} ]]; then
					_goggy_log info "Removing config ..."
					rm -rf "$(dirname "${goggyconfig}")"
				else
					_goggy_log info "Retainig config at '${goggyconfig}'."
				fi
			else
				_goggy_log info "Aborting."
			fi

			return ${rval}
		;;

		l|list)
			_goggy_log verbose "Iterating linked gameinfo files ..."
			for gameinfo in $(ls "${goggyroot}/installed"); do
				local name=$(cat "${goggyroot}/installed/${gameinfo}" | jq .name)
				local gameid=$(cat ${goggyroot}/installed/${gameinfo} | jq .gameId | tr -dc '0-9')
				echo "${gameid} ${name}"
			done
		;;

		i|install)
			if (( 2 > $# )); then
				local usage="usage: ${self} ${cmd} <options> [*.pkg]"
				usage="${usage}\noptions:"
				usage="${usage}\n\t-R\tRetain temporary files."

				printf "%b" "${usage}"

				return 13
			fi

			local shouldretain=0

			shift
			while getopts R arg; do
				case ${arg} in
					R)
						shouldretain=1
						;;

					:)
					  _goggy_log error "Option -${OPTARG} requires an argument."

					  return 13
					  ;;

					\?|*)
					  _goggy_log error "Invalid option: -${OPTARG}."

					  return 13
					  ;;
				esac
			done
			shift $(( OPTIND - 1 ))
			local positionalargs=( "$@" )

			local pkgsrc="${1}"
			echo "$pkgsrc"
			local pkg="$(realpath -s ${pkgsrc})"
			if [ ! -e "${pkg}" ]; then
				_goggy_log error "Could not find ${pkg}!"

				return 13
			fi

			local ts=$(python3 -c "import time; print(time.time())")
			local tmppath="${cacheroot}/$ts"
			mkdir -p "${tmppath}"; pushd "${tmppath}" > /dev/null
				echo "Extracting '${pkg}' ..."
				if ! 7z x "$pkg" -o"${tmppath}" > /dev/null; then
					_goggy_log error "Could not unpack given pack file."

					return 13
				fi

				local datapk="package.pkg/Scripts"
				if [ ! -e "${datapk}" ]; then
					_goggy_log error "Package does not seem to have any contents."

					_goggy_log error "Contents:"
					_goggy_log error "$(ls -lav .)"

					_goggy_log warning "Discarding temporary data ..."
					rm -rf "${tmppath}"

					popd > /dev/null
					return 13
				fi

				local rawpak="unpacked"
				mkdir -p ${rawpak}
				cat "${datapk}" | gunzip -dc | cpio -i -D "${rawpak}"

				if [ ! -e "${rawpak}/payload/Contents" ]; then
					_goggy_log error "Appears inner package data has no 'Contents'."
					_goggy_log error "Inner package:"
					ls -lav "${rawpak}"
				else
					local gameinfosrc=$(find \
						"${rawpak}/payload/Contents" -iname "*.info" \
						| head -n 1 \
					)
					local gameinfoid=$(basename -s .info "${gameinfosrc/goggame-/}")
					echo "Found gameinfo at '${gameinfosrc}' with id ${gameinfoid}."

					local out=$(realpath -s "${goggyroot}/games/${gameinfoid}")
					if [ -e "${out}" ]; then
						_goggy_log error "Game path already present at '${out}'."
					else
						echo "Creating game path at '${out}' ..."
						mkdir "${out}"

						echo "Copying game data ..."
						cp -Ra "${rawpak}"/* "${out}"

						local gameinfolive=$(find \
							"${out}/payload/Contents" -iname "*.info" \
							| head -n 1 \
						)
						echo "Linking game info ..."
						if ! ln -f -s \
							"${gameinfolive}" \
							"${goggyroot}/installed/${gameinfoid}.info"
						then
							_goggy_log error \
								"Could not link game info." \
								"Seems like fragments from a previous installation." \
								"Try removing them from '${goggyroot}' and try again."
						else
							echo "Game '${gameinfoid}' ready for play."
						fi
					fi
				fi				
			popd > /dev/null

			if [ 0 = ${shouldretain} ]; then
				_goggy_log warning "Discarding temporary data ..."
				rm -rf "${tmppath}"
			else
				_goggy_log warning "Retaining temporary data at '${tmppath}' ..."
			fi
		;;

		u|uninstall)
			shift
			if ((  1 > $# )); then
				local usage="usage: ${self} ${cmd} [gameid]"
				printf "%b" "${usage}"

				return 13
			fi

			local didremove=0
			local gameid="${1}"
			local gamedir="$(realpath -s "${goggyroot}/games/${gameid}" 2> /dev/null)"
			local gameinfo="$(realpath -s "${goggyroot}/installed/${gameid}.info")"
			
			echo "Discarding game with id ${gameid} ..."
			if ! [ -e "${gamedir}" ]; then
				_goggy_log error \
					"Game with id ${gameid}, does not appear to be installed."
			else
				echo "Removing game directory ..."
				rm -rf "${gamedir}"
				didremove=1
			fi

			if ! [ -h "${gameinfo}" ]; then
				_goggy_log error "Link to metadata not found at '${gameinfo}'."
			else
				echo "Removing game info link ..."
				rm "${gameinfo}"
				didremove=1
			fi

			if ! [ 0 = ${didremove} ]; then
				echo "Game with id '${gameid}' removed."

				return 0
			fi

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
				_goggy_log error "Game with ID ${gameid} is not installed."

				return 13
			fi

			local mode="$2"
			local gameroot="${goggyroot}/scripts/${gameid}"
			_goggy_log info "Looking for game at '${gameroot}' ..."
			if [ ! -e ${gameroot} ]; then
				_goggy_log error "Could not find game root for id ${gameid}!"

				return 13
			fi

			local name=$(cat "${goggyroot}/installed/${gameid}.info" \
				| jq .name \
			)
			echo "Playing $name ($gameid) ..."
			pushd ${gameroot} > /dev/null
				./play.sh ${mode}
			popd > /dev/null
		;;

		c|cleanup)
			local tmproot="$(dirname $(mktemp))"
			for cachedir in \
				$(find $(dirname $(mktemp)) -iname "*.goggy" 2> /dev/null)
			do
				_goggy_log info "Found: ${cachedir}, removing ..."
				rm -rf "${cachedir}"
			done
		;;

		v|version)
			echo "1.6.18"
		;;

		*)
			local usage="USAGE: ${self} <options> [command] ..."
			usage="${usage}\ncommands (short-hand):"
			usage="${usage}\n\tsetup (s)\tSets up goggy directories and config."
			usage="${usage}\n\tpurge (p)\tRemoves goggy from the system."
			usage="${usage}\n\tlist (l)\tLists all installed games."
			usage="${usage}\n\tinstall (i)\Installs new game."
			usage="${usage}\n\tuninstall (u)\tRemoves installed game."
			usage="${usage}\n\tplay (p)\tStarts an installed game."
			usage="${usage}\n\tcleanup (c)\tRemoves all cached files."
			usage="${usage}\n\tversion (v)\tShows version."

			printf "%b" "${usage}"

			return 13
		;;
	esac

	return $?
}

goggy $*
