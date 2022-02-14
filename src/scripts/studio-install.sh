#!/bin/bash

#########################
# HELP
#########################

export DEBIAN_FRONTEND=noninteractive

help()
{
  echo "This script installs Nebula Graph Studio on Ubuntu"
  echo ""
  echo "Options:"
  echo "    -v      nebula studio version, default: 3.2.1"

  echo "    -h      view this help content"
}

log()
{
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1"
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1" >> /var/log/arm-studio-install.log
}

log "Begin execution of Nebula Graph Studio script extension on ${HOSTNAME}"
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

STUDIO_VERSION="3.2.1"

#Loop through options passed
while getopts :v:h optname; do
  log "Option ${optname} set"
  case $optname in
  v) # set nebula version
    STUDIO_VERSION="${OPTARG}"
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

# Install Nebula Graph Studio
install_studio()
{
    local PACKAGE="nebula-graph-studio-${STUDIO_VERSION}.x86_64.deb"
    local DOWNLOAD_URL="https://oss-cdn.nebula-graph.com.cn/nebula-graph-studio/${STUDIO_VERSION}/nebula-graph-studio-${STUDIO_VERSION}.x86_64.deb"

    log "[install_studio] installing Nebula Graph Studio ${STUDIO_VERSION}"
    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE
    local EXIT_CODE=$?
        if [[ $EXIT_CODE -ne 0 ]]; then
        log "[install_nebula] error downloading Nebula Graph Studio $STUDIO_VERSION"
        exit $EXIT_CODE
    fi

    dpkg -i $PACKAGE

    log "[install_studio] installed Nebula Graph Studio $STUDIO_VERSION"
}

configure_systemd()
{
    log "[configure_systemd] configure systemd to start Studio service automatically when system boots"
    systemctl daemon-reload
    systemctl enable nebula-graph-studio.service
}

start_systemd()
{
    log "[start_systemd] starting Studio"
    systemctl start nebula-graph-studio.service
    log "[start_systemd] started Studio"
}

#########################
# Installation sequence
#########################

# if studio is already installed assume this is a redeploy
if systemctl -q is-active nebula-graph-studio.service; then
  exit 0
fi

install_studio

configure_systemd

start_systemd

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of Nebula Graph Studio script extension on ${HOSTNAME} in ${PRETTY}"
exit 0