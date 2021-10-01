#!/bin/bash
# we only want to source the file once
if [[ $__isLibSourced ]]; then
    return
else
    readonly __isLibSourced=1
fi

# only code that executes when lib is sourced should be the init code
# this is to prevent multiple inits when the script is sourced multiple times
function __init_logger() {
    # call init function
    # shellcheck disable=SC1091
    __init_log
}

function __init_log() {

    #variables - which can be exported
    #SCRIPTNAME="$(basename ${BASH_SOURCE[0]})"
    SCRIPTPATH_FULL="$(realpath "${BASH_SOURCE[0]}")"
    SCRIPTDIR="$(dirname "${SCRIPTPATH_FULL}")"
    DATETIME=$(date +%Y%m%d%H%M%S)
    INFOLOGFILENAME="infolog-${DATETIME}.txt"
    DEBUGLOGFILENAME="debuglog-${DATETIME}.txt"
    PROCESS_OF_LOGGER="$$"

    readonly PROCESS_OF_LOGGER

    #save stdout and stderr file discriptors
    exec 3>&1 4>&2

    # initialize log files and redirect stdout and stderr to log files
    printf '%(%Y-%m-%d %H:%M:%S)T %-7s %s\n' -1 INFO \
            "excution started at : '${DATETIME}'" > "${INFOLOGFILENAME}" 
    
    printf '%(%Y-%m-%d %H:%M:%S)T %-7s %s\n' -1 DEBUG \
            "execution started at : '${DATETIME}'" > "${DEBUGLOGFILENAME}"
    
    # redirect info log to debug log and send the process to background
    # this way we can close the file handles at the end of the script
    tail -f "${INFOLOGFILENAME}" | tee -a "${DEBUGLOGFILENAME}" &
    PROCESS_OF_BCK_LOGGER=$!
    readonly PROCESS_OF_BCK_LOGGER
    
    #redirect stdout and stderr to log files
    exec 1> >(tee -a "${DEBUGLOGFILENAME}") 2> >(tee -a "${DEBUGLOGFILENAME}" >&2)

    # letting colors be defined, use cat, less -R or tail to see the colors
    # if cat is not displaying colors, then the control characters may not be
    # intact. Look at the following link for more info:
    # https://unix.stackexchange.com/questions/262185/

    # shellcheck disable=SC2034
    if [ -t 1 ]; then
        # set up colors
        [[ $color_normal ]] || color_normal="\033[0m"
        [[ $color_red ]] || color_red="\033[0;31m"
        [[ $color_green ]] || color_green="\033[0;32m"
        [[ $color_yellow ]] || color_yellow="\033[0;33m"
        [[ $color_magenta ]] || color_magenta="\033[0;35m"
        [[ $color_cyan ]] || color_cyan="\033[0;36m"
        [[ $color_white ]] || color_white="\033[0;37m"
    else
        # no colors when stdout is not a terminal
        color_normal=""
        color_red=""
        color_green=""
        color_yellow=""
        color_magenta=""
        color_cyan=""
        color_white=""
    fi

    readonly color_normal color_red color_green color_yellow color_magenta \
                color_cyan color_white

    # clear out any old values
    # shellcheck disable=SC2034
    unset log_levels log_levels_map
    # shellcheck disable=SC2034
    declare -gA log_levels log_levels_map

    # create hash table of log levels
    log_levels=([SUCCESS]=0 [ERROR]=1 [WARN]=2 [INFO]=3 [DEBUG]=4 [VERBOSE]=5)

    # set default log level mapper to INFO
    log_level_mapper["default"]=3
    
    # set the trap to catch the script termination
    # shellcheck disable=SC2034
    trap reset_file_descriptors EXIT HUP INT ABRT QUIT TERM
}

# set log level function
function set_log_level() {
    local logger=default curr_log_level l
    [[ $1 = "-l" ]] && {
        logger=$2
        shift 2 2>/dev/null
    }
    curr_log_level="${1:-INFO}"
    if [[ $logger ]]; then
        l="${log_levels[$curr_log_level]}"
        if [[ $l ]]; then
            log_level_mapper[$logger]=$l
        else
            printf '%(%Y-%m-%d %H:%M:%S)T %-7s %s\n' -1 WARN \
                "${BASH_SOURCE[2]}:${BASH_LINENO[1]} Unknown log level `
                `'$curr_log_level' for logger '$logger'; setting to INFO"
            log_level_mapper[$logger]=3
        fi
    else
        printf '%(%Y-%m-%d %H:%M:%S)T %-7s %s\n' -1 WARN \
            "${BASH_SOURCE[2]}:${BASH_LINENO[1]} Option '-l' needs an argument" >&2
    fi
}

# Core and private log printing logic to be called by all logging functions
# use bash internal printf to format the output
function _printlog() {
    local current_log_level=$1
    shift
    local logger=default log_level_set log_level
    [[ $1 = "-l" ]] && {
        logger=$2
        shift 2
    }
    log_level="${log_levels[$current_log_level]}"
    log_level_set="${log_level_mapper[$logger]}"

    #+${BASH_SOURCE/$HOME/\~}@${LINENO}${FUNCNAME:+(${FUNCNAME[0]})}:
    #who_called="+${BASH_SOURCE[2]}@${BASH_LINENO[1]}:${FUNCNAME[2]}:"
    who_called="+${BASH_SOURCE/$DEPLOYMENT_REPO_PATH/\~}@`
                `${LINENO}${FUNCNAME:+(${FUNCNAME[0]})}:"

    if [[ $log_level_set ]]; then
        ((log_level_set >= log_level)) && {
            printf '%(%Y-%m-%d:%H:%M:%S)T %-7s %s\n' -1 "$current_log_level" \
                    "$who_called"
            printf '%s\n' "$@"
        }
    else
        printf '%(%Y-%m-%d:%H:%M:%S)T %-7s %s\n' -1 WARN \
            "$who_called Unknown logger '$logger'; setting to default"
    fi
}

function _writelog_to_file() {
    local current_log_level=$1
    shift
    local logger=default log_level_set log_level
    [[ $1 = "-l" ]] && {
        logger=$2
        shift 2
    }
    #log_file=$1
    log_file="${SCRIPTDIR}/$1"
    #writes a message to the log log_file
    # we may not need this, if the log file doesn't exist, create it
    if [ ! -f "${log_file}" ]; then
        touch "${log_file}"
    fi
    log_level="${log_levels[$current_log_level]}"
    log_level_set="${log_level_mapper[$logger]}"

    who_called="+${BASH_SOURCE[2]/$DEPLOYMENT_REPO_PATH/\~}@`
                `${BASH_LINENO[1]}:${FUNCNAME[2]}:"

    if [[ $log_level_set ]]; then
        if ((log_level_set >= log_level)) && [[ -f "${log_file}" ]]; then
            shift 1
            printf '%(%Y-%m-%d:%H:%M:%S)T %-7s %s %s\n' -1 "$current_log_level" \
                "$who_called" "$@" >>"${log_file}"
        else
            shift 1
            printf '%(%Y-%m-%d:%H:%M:%S)T %-7s %s %s\n' -1 "$current_log_level" \
                "$who_called" "$@" >>"${log_file}"
        fi
    else
        printf '%(%Y-%m-%d:%H:%M:%S)T %-7s %s\n' -1 WARN \
            "$who_called Unknown logger '$logger'; setting to default"
    fi

}

#placeholder, we need to decide if we ever need to _printlog_from_file() 


# main logging functions
#
log_critical() { _printlog CRITICAL "$@"; }
log_error() { _printlog ERROR "$@"; }
log_warn() { _printlog WARN "$@"; }
log_info() { _printlog INFO "$@"; }
log_debug() { _printlog DEBUG "$@"; }
log_verbose() { _printlog VERBOSE "$@"; }
#
# logging file content
#
log_info_file()    { _writelog_to_file INFO "$@";    }
log_debug_file()   { _writelog_to_file DEBUG "$@";   }
log_verbose_file() { _writelog_to_file VERBOSE "$@"; }

#
# logging for function entry and exit
#
log_info_enter() { _printlog INFO "Entering function ${FUNCNAME[1]}"; }
log_debug_enter() { _printlog DEBUG "Entering function ${FUNCNAME[1]}"; }
log_verbose_enter() { _printlog VERBOSE "Entering function ${FUNCNAME[1]}"; }
log_info_leave() { _printlog INFO "Leaving function ${FUNCNAME[1]}"; }
log_debug_leave() { _printlog DEBUG "Leaving function ${FUNCNAME[1]}"; }
log_verbose_leave() { _printlog VERBOSE "Leaving function ${FUNCNAME[1]}"; }

function reset_file_descriptors() {
    # reset file descriptors to default
    # this is useful for scripts that fork and exec
    exec 2>&4 1>&3
    # close the additional file descriptors
    exec 3>&- 4>&-
    
    # remove the background process for log file
    pkill -P "${PROCESS_OF_BCK_LOGGER}"
    # remove the process for log file
    pkill -P "${PROCESS_OF_LOGGER}"
}

dump_stack_trace() {
    local frame=0 line func source n=0
    while caller "$frame"; do
        ((frame++))
    done | while read -r line func source; do
        ((n++ == 0)) && {
            printf 'Encountered a fatal error\n'
        }
        printf '%4s at %s\n' " " "$func ($source:$line)"
    done
}

exit_if_error() {
    (($#)) || return
    local num_re='^[0-9]+'
    local rc=$1
    shift
    local message="${@:-No message specified}"
    if ! [[ $rc =~ $num_re ]]; then
        log_error "'$rc' is not a valid exit code; it needs to be a number greater than zero. Treating it as 1."
        rc=1
    fi
    ((rc)) && {
        log_critical "$message"
        dump_stack_trace "$@"
        exit $rc
    }
    return 0
}

fatal_error() {
    local ec=$?         # grab the current exit code
    ((ec == 0)) && ec=1 # if it is zero, set exit code to 1
    exit_if_error "$ec" "$@"
}

__init_logger
#########################################################################
#     (( )) -> math mode
#     $# -> number of params
#     ${#var_name} -> length of var_name
#     ${#var_name[@]} -> count elements in the array
#     : -> if condition
#     ${varname:-<default_value>} -> if varname is null, use default_value
#     ${varname:<default_value>} -> if varname is not null but empty string, use default_value
#     ${varname:+<default_value>} -> if varname is not null and not empty string, use default_value
#     ${varname:?<error_message>} -> if varname is null, print error_message and exit
#     example: ${debug:+-d} or ${DEBUG:+--verbose}
#     ${var:+ ${var}} -> if var is set, substitute with space and var value
# Acknowledgements: Fergal Mc Carthy, SUSE
#########################################################################
#error codes include those from /usr/include/sysexits.h

# function log_info() {
#     echo -e "${INFO_COLOR}${PROCESS_OF_LOGGER} ${1}${RESET_COLOR}"
# }

# function strip_colors() {
#     #strip all control characters and colors from a string
#     echo -e "${1}" | sed -e 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'
# }

# function writelog() {
#     #writes a message to the log file
#     #if the log file doesn't exist, create it
#     if [ ! -f "${SCRIPTDIR}/${INFOLOGFILENAME}" ]; then
#         touch "${SCRIPTDIR}/${INFOLOGFILENAME}"
#     fi
#     strip_colors "${1}" >> "${SCRIPTDIR}/${INFOLOGFILENAME}"
# }