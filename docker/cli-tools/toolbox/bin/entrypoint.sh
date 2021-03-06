#!/usr/bin/env bash
[[ "${FR_DEBUG}" == true ]] && set -x

WORKSPACE="${WORKSPACE:-/opt/workspace}"
cd $WORKSPACE

if [[ ! -f "${WORKSPACE}/.CONFIGURED" ]];
then
  echo "Configuring workspace"
  git clone --origin upstream --depth 1 https://github.com/ForgeRock/forgeops.git
  cp -r /opt/build/* .
  touch "${WORKSPACE}/.CONFIGURED"
  echo "done"
fi

# No used anymore. Leaving in case we want to renable
#echo "${SSH_PUBKEY}" >> ~/.ssh/authorized_keys
#printenv >> ~/.ssh/environment

# Needed for VSCode remote support
#exec /usr/sbin/sshd -D -p "${SSH_PORT}" -f ~/etc/sshd_config
# Need for VSCode
# exec /usr/sbin/sshd -D -p "${SSH_PORT}"

# The pod should execute with args: ["pause"]
exec $*
