#!/bin/bash
#------------------------------------------------------------------------------
#
#   TODO
#
#   7d2d-bk-clean.sh
#
#   7daystodie backup cleaner
#
#------------------------------------------------------------------------------
set -u
umask 0022
export LC_ALL=C
readonly SCRIPT_NAME=$(basename $0)
readonly SCRIPT_DIR=$(dirname $(readlink -f $0))

# Load parameters
. $SCRIPT_DIR/.env


#------------------------------------------------------------------------------
#   Utils
#------------------------------------------------------------------------------
usage() {
    cat <<__EOS__
Usage:
    $SCRIPT_NAME [-h] COMMAND [COMMAND_OPTION]
    $SCRIPT_NAME clean [BACKUP_PATH]

Description:
    7daystodie backup cleaner.

Commands:
    clean           remove backups remain todays.(default)

Options:
    -h              show usage.
__EOS__
}

err() {
    echo -e "Error: $@\n" 1>&2
    exit 1
}

dump_params() {
    cat <<__EOS__
*** Dump 7d2d.sh Params ***
SERVICE_7D2D                  : $SERVICE_7D2D
PATH_7D2D                     : $PATH_7D2D

* Configs
PATH_7D2D_CONFIG_DIR          : $PATH_7D2D_CONFIG_DIR
PATH_7D2D_CONFIG_SERVER_XML   : $PATH_7D2D_CONFIG_SERVER_XML
PATH_7D2D_CONFIG_7D2D_CONF    : $PATH_7D2D_CONFIG_7D2D_CONF

* Applications
PATH_7D2D_APP_DIR             : $PATH_7D2D_APP_DIR
PATH_7D2D_APP_MODS_DIR        : $PATH_7D2D_APP_MODS_DIR

* Backups
PATH_BACKUP_DIR               : $PATH_BACKUP_DIR
PATH_BACKUP_CONFIGS_DIR       : $PATH_BACKUP_CONFIGS_DIR
PATH_BACKUP_MODS_DIR          : $PATH_BACKUP_MODS_DIR

* Control Panel
CP_TELNET_HOST                : $CP_TELNET_HOST
CP_TELNET_PORT                : $CP_TELNET_PORT
__EOS__
}

parse_args() {
    while getopts h flag; do
        case "${flag}" in
            h )
                usage
                exit 0
                ;;

            * )
                usage
                exit 0
                ;;
        esac
    done
}

extract_date() {
    # --- fromat: "2020/12/31T00:00:02" ---
    #local yd=""
    #local t=""
    #if [[ $1 =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    #    yd="${BASH_REMATCH[1]//-/\/}"
    #fi
    #if [[ $1 =~ (__[0-9]{2}-[0-9]{2}-[0-9]{2}) ]]; then
    #    t="${BASH_REMATCH[1]##*__}"
    #    t="${t//-/:}"
    #fi
    #echo "${yd}T${t}"

    # --- format: numebr only ---
    local yd=""
    local t=""
    if [[ $1 =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        yd="${BASH_REMATCH[1]//-/}"
    fi
    if [[ $1 =~ (__[0-9]{2}-[0-9]{2}-[0-9]{2}) ]]; then
        t="${BASH_REMATCH[1]##*__}"
        t="${t//-/}"
    fi
    echo "${yd}${t}"
}


#------------------------------------------------------------------------------
#   Commands
#------------------------------------------------------------------------------
clean_bk_files() {
    local bk_path="${1%/}"
    local today=$(date "+%Y/%m/%dT%H:%M:%S")
    local dline=$(date -d '3 days ago' "+%Y%m%d%H%M%S")
    local cnt=0

    for path in $(ls $bk_path); do
        local file=$(basename $path)

        local type=""
        if [[ ! "$file" == *.tar.gz ]]; then
            continue
        elif [[ "$file" == *"full"* ]]; then
            type="full"
        elif [[ "$file" == *"diff"* ]]; then
            type="diff"
        fi

        dat=$(extract_date "$file")

        # Skip recent backups.
        if [[ "$dat" > "$dline" ]]; then
            continue   # skip
        fi


        # remove file
        rm "$bk_path/$file"
        echo "[$today] 7d2d-bk-clean: [$type] $file --- deleted."
        cnt=$((cnt+1))
    done

    echo "[$today] 7d2d-bk-clean: $cnt files deleted."
}


#------------------------------------------------------------------------------
#   Entrypoint
#------------------------------------------------------------------------------
main() {
    parse_args $@
    shift `expr $OPTIND - 1`

    # no command
    local cmd="${1+$1}"
    if [ -z "$cmd" ]; then
        cmd="clean"
    fi
    local opt="${2+$2}"

    case "$cmd" in
        #----------------------------------------------------------------------
        # Clean backup files
        clean )
            clean_bk_files $opt
            ;;

        #----------------------------------------------------------------------
        # debugs
        dump )
            dump_params
            exit 0
            ;;

        * )
            err "invalid operator $cmd"
            ;;
    esac
}

main $@
exit 0

