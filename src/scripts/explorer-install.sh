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
  echo "    -v      nebula explorer version, default: 2.2.0"
  echo "    -l      nebula license"

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

EXPLORER_VERSION="2.2.0"
NEBULA_LICENSE=""
NEBULA_LICENSE_PATH="/usr/local/nebula-explorer/nebula.license"

#Loop through options passed
while getopts :v:l:h optname; do
  log "Option ${optname} set"
  case $optname in
  v) # set nebula version
    EXPLORER_VERSION="${OPTARG}"
    ;;
  l) #set nebula license
    NEBULA_LICENSE="${OPTARG}"
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
    local PACKAGE="nebula-explorer-${EXPLORER_VERSION}.x86_64.deb"

#    local DOWNLOAD_URL=""
#    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE

    log "[install_explorer] installing Nebula Graph Explorer ${EXPLORER_VERSION}"

    chmod +x nebula-download
    ./nebula-download explorer --name $PACKAGE --version $EXPLORER_VERSION

    local EXIT_CODE=$?
        if [[ $EXIT_CODE -ne 0 ]]; then
        log "[install_nebula] error downloading Nebula Graph Explorer $EXPLORER_VERSION"
        exit $EXIT_CODE
    fi

    dpkg -i $PACKAGE

    log "[install_explorer] installed Nebula Graph Explorer $EXPLORER_VERSION"
}

# Security
configure_license()
{
  if [[ -n "${NEBULA_LICENSE}" ]]; then
    log "[configure_license] save Nebula License to file"
    echo "${NEBULA_LICENSE}" > $NEBULA_LICENSE_PATH
  fi
}

configure_systemd()
{
    log "[configure_systemd] configure systemd to start Explorer service automatically when system boots"
    systemctl daemon-reload
    systemctl enable nebula-explorer.service
}

start_systemd()
{
    log "[start_systemd] starting Explorer"
    systemctl start nebula-explorer.service
    log "[start_systemd] started Explorer"
}

#########################
# Installation sequence
#########################

# if explorer is already installed assume this is a redeploy
if systemctl -q is-active nebula-explorer.service; then
  exit 0
fi

mkdir -p "/usr/lib/systemd/system"

install_explorer

configure_license

configure_systemd

start_systemd

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of Nebula Graph Explorer script extension on ${HOSTNAME} in ${PRETTY}"
exit 0