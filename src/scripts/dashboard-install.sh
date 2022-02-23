#!/bin/bash

#########################
# HELP
#########################

export DEBIAN_FRONTEND=noninteractive

help()
{
  echo "This script installs Nebula Graph Dashboard on Ubuntu"
  echo ""
  echo "Options:"
  echo "    -v      nebula dashboard version, default: 1.1.0"
  echo "    -l      nebula license"

  echo "    -h      view this help content"
}

log()
{
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1"
    echo \[$(date +%Y/%m/%d-%H:%M:%S)\] "$1" >> /var/log/arm-dashboard-install.log
}

log "Begin execution of Nebula Graph Dashboard script extension on ${HOSTNAME}"
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

DASHBOARD_VERSION="1.1.0"
DASHBOARD_PATH="/usr/local/nebula-dashboard"
NEBULA_LICENSE=""
NEBULA_LICENSE_PATH="${DASHBOARD_PATH}/nebula-dashboard-ent/nebula.license"

#Loop through options passed
while getopts :v:l:h optname; do
  log "Option ${optname} set"
  case $optname in
  v) # set nebula version
    DASHBOARD_VERSION="${OPTARG}"
    ;;
  h) #show help
    help
    exit 2
    ;;
  l) #set nebula license
    NEBULA_LICENSE="${OPTARG}"
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

# Install Nebula Graph Dashboard
install_dashboard()
{
    local PACKAGE="nebula-dashboard-ent-${DASHBOARD_VERSION}.linux-amd64.tar.gz"

#    local DOWNLOAD_URL=""
#    wget --retry-connrefused --waitretry=1 -q "$DOWNLOAD_URL" -O $PACKAGE

    log "[install_dashboard] installing Nebula Graph Dashboard ${DASHBOARD_VERSION}"

    chmod +x nebula-download
    ./nebula-download dashboard --name $PACKAGE --version $DASHBOARD_VERSION

    local EXIT_CODE=$?
        if [[ $EXIT_CODE -ne 0 ]]; then
        log "[install_dashboard] error downloading Nebula Graph Dashboard $DASHBOARD_VERSION"
        exit $EXIT_CODE
    fi

    mkdir -p $DASHBOARD_PATH
    tar -zxvf $PACKAGE -C $DASHBOARD_PATH

    log "[install_dashboard] installed Nebula Graph Dashboard $DASHBOARD_VERSION"
}

install_mysql()
{
  log "[install_mysql] installing mysql"
  apt-get -yq install mysql-server

  systemctl -q is-active mysql
  EXIT_CODE=$?
  if [[ $EXIT_CODE -ne 0 ]]; then
    log "[install_mysql] returned non-zero exit code: $EXIT_CODE"
    exit $EXIT_CODE
  fi
  log "[install_mysql] installed mysql"
}

configure_mysql()
{
 log "[configure_mysql] configure mysql"
  mysql < "init_dashboard.sql"
}

# Security
configure_license()
{
  if [[ -n "${NEBULA_LICENSE}" ]]; then
    log "[configure_license] save Nebula License to file"
      echo ${NEBULA_LICENSE} | base64 -d | tee $NEBULA_LICENSE_PATH
  fi
}

#configure_systemd()
#{
#    log "[configure_systemd] configure systemd to start Dashboard service automatically when system boots"
#    systemctl daemon-reload
#    systemctl enable nebula-graph-dashboard.service
#}
#
#start_systemd()
#{
#    log "[start_systemd] starting Dashboard"
#    systemctl start nebula-graph-dashboard.service
#    log "[start_systemd] started Dashboard"
#}

start_dashboard()
{
  log "[start_systemd] starting Dashboard"
  $DASHBOARD_PATH/nebula-dashboard-ent/scripts/dashboard.service start all
  log "[start_systemd] started Dashboard"
}

#########################
# Installation sequence
#########################

# if dashboard is already installed assume this is a redeploy
#if systemctl -q is-active nebula-graph-dashboard.service; then
#  exit 0
#fi

log "updating apt-get"
apt-get -yq update
log "updated apt-get"

if ! systemctl -q is-active mysql; then
  install_mysql
  configure_mysql
fi

install_dashboard

configure_license

start_dashboard

ELAPSED_TIME=$(($SECONDS - $START_TIME))
PRETTY=$(printf '%dh:%dm:%ds\n' $(($ELAPSED_TIME/3600)) $(($ELAPSED_TIME%3600/60)) $(($ELAPSED_TIME%60)))

log "End execution of Nebula Graph Dashboard script extension on ${HOSTNAME} in ${PRETTY}"
exit 0