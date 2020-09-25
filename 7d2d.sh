#!/bin/bash
#------------------------------------------------------------------------------
#
#   7d2d.sh
#
#   7daystodie server management support script.
#
#------------------------------------------------------------------------------
set -u
umask 0022
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

Description:
    7daystodie server management support.

Commands:
    start           start 7daystodie service.
    stop            stop 7daystodie service.
    status, st      show status of 7daystodie service
    restart         restart 7daystodie service.

    cp, telnet      Connect control panel via telnet.


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

mkdir_if_not_exist() {
    if [ ! -d "$1" ]; then
        mkdir -p $1
    fi
}



#------------------------------------------------------------------------------
#   Commands
#------------------------------------------------------------------------------
exec_systemctl() {
    local cmd="$1"
    sudo systemctl $cmd $SERVICE_7D2D
}

exec_edit() {
    local target="$1"

    case "$target" in
        server  ) sudoedit $PATH_7D2D_CONFIG_SERVER_XML ;;
        7d2d    ) sudoedit $PATH_7D2D_CONFIG_7D2D_CONF  ;;
    esac
}

exec_backup() {
    local target="$1"
    local bk_suffix=$(date +%Y-%m-%d_%H%M%S)
    local bk_path=""

    case  "$target" in
        config )
            bk_path="$PATH_BACKUP_CONFIGS_DIR/config-$bk_suffix"
            mkdir_if_not_exist $PATH_BACKUP_CONFIGS_DIR
            cp -R $PATH_7D2D_CONFIG_DIR $bk_path
            ;;

        mods )
            if [ -z "$(ls $PATH_7D2D_APP_MODS_DIR)" ]; then
                echo "No mods yet."
            else
                bk_path="$PATH_BACKUP_MODS_DIR/mods-$bk_suffix"
                mkdir_if_not_exist $PATH_BACKUP_MODS_DIR
                cp -R $PATH_7D2D_APP_MODS_DIR $bk_path
            fi
            ;;
    esac

    if [ -n $bk_path ]; then
        echo "Backup $target completed: $bk_path"
    else
        echo "Backup skipped."
    fi
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
        cmd="status"
    fi
    local opt="${2+$2}"

    case "$cmd" in
        #----------------------------------------------------------------------
        # Systemctl
        start       ) exec_systemctl "start"    ;;
        stop        ) exec_systemctl "stop"     ;;
        status | st ) exec_systemctl "status"   ;;
        restart     ) exec_systemctl "restart"  ;;

        #----------------------------------------------------------------------
        # Control Panel
        cp | telnet )
            telnet $CP_TELNET_HOST $CP_TELNET_PORT
            ;;

        #----------------------------------------------------------------------
        # configs
        edit )
            if [ -z "$opt" ]; then
                opt="server"
            fi
            exec_edit $opt
            ;;

        #----------------------------------------------------------------------
        # mods
        lsmod )
            ls -al $PATH_7D2D_APP_MODS_DIR
            ;;

        #----------------------------------------------------------------------
        # backups
        bk | backup )
            exec_backup "$opt"
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

