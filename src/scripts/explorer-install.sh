#!/bin/bash

#########################
# HELP
#########################

export DEBIAN_FRONTEND=noninteractive

help()
{
  echo "This script installs Nebula Graph Explorer on Ubuntu"
  echo ""
  echo "Options:"
  echo "    -v      nebula explorer version, default: 1.1.0"

  echo "    -h      view this help content"
}

log()
{
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1"
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1" >> /var/log/arm-explorer-install.log
}

log "Begin execution of Nebula Graph Explorer script extension on ${HOSTNAME}"
START_TIME=$SECONDS

#########################
# Preconditions
#########################

if [ "${UID}" -ne 0 ];
then
    log "Script executed without root permissions"
    echo "You must be root to run this program." >&2
    exit 3
fi

#########################
# Parameter handling
#########################

EXPLORER_VERSION="3.1.0"

#Loop through options passed
while getopts :v:h optname; do
  log "Option ${optname} set"
  case $optname in
  v) # set nebula version
    EXPLORER_VERSION="${OPTARG}"
    ;;
  h) #show help
    help
    exit 2
    ;;
  \?) #unrecognized option - show help
    echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
    help
    exit 2
    ;;
  esac
done

#########################
# Installation steps as functions
#########################

# Install Nebula Graph Explorer
install_explorer()
{
    local PACKAGE=""
    local DOWNLOAD_URL=""

    log "[install_explorer] installing Nebula Graph Explorer ${EXPLORER_VERSION}"
    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE
    local EXIT_CODE=$?
        if [[ $EXIT_CODE -ne 0 ]]; then
        log "[install_nebula] error downloading Nebula Graph Explorer $EXPLORER_VERSION"
        exit $EXIT_CODE
    fi

    dpkg -i $PACKAGE

    log "[install_explorer] installed Nebula Graph Explorer $EXPLORER_VERSION"
}

configure_systemd()
{
    log "[configure_systemd] configure systemd to start Explorer service automatically when system boots"
    systemctl daemon-reload
    systemctl enable nebula-graph-explorer.service
}

start_systemd()
{
    log "[start_systemd] starting Explorer"
    systemctl start nebula-graph-explorer.service
    log "[start_systemd] started Explorer"
}

#########################
# Installation sequence
#########################

# if explorer is already installed assume this is a redeploy
if systemctl -q is-active nebula-graph-explorer.service; then
  exit 0
fi

install_explorer

configure_systemd

start_systemd

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of Nebula Graph Explorer script extension on ${HOSTNAME} in ${PRETTY}"
exit 0