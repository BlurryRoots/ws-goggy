#!/bin/bash
# (c) 2023 Sven Freiberg

# Setup log level constants.
export _GOGGY_LOG_VERBOSE=3
export _GOGGY_LOG_INFO=2
export _GOGGY_LOG_WARNING=1
export _GOGGY_LOG_ERROR=0

# Setup log level usage.
export _GOGGY_LOG_LVL=$_GOGGY_LOG_INFO
# Setup log level level lookup by name.
declare -A _GOGGY_LVLS=( ["verbose"]=$_GOGGY_LOG_VERBOSE \
	["info"]=$_GOGGY_LOG_INFO \
	["warning"]=$_GOGGY_LOG_WARNING \
	["error"]=$_GOGGY_LOG_ERROR \
)
export _GOGGY_LVLS

# Define logging helper function.
_goggy_log () {
	local lvl=${1}

	local lvln=${_GOGGY_LVLS[${lvl}]}
	if (( ${lvln} <= $_GOGGY_LOG_LVL )); then
		echo "log(${lvl}): ${@:2}" >&2
	fi
}
