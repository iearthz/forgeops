#!/usr/bin/env bash
# Run the OpenDJ server
# We consolidate all of the writable DJ directories to /opt/opendj/data
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ.
# For Docker - mount a data volume on /opt/opendj/data
# For Kubernetes mount a PV
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

cd /opt/opendj

# If the pod was terminated abnormally the lock file may not have gotten cleaned up.

rm -f /opt/opendj/locks/server.lock
mkdir -p locks


# Uncomment this to print experimental VM settings to stdout.
#java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -XshowSettings:vm -version

source /opt/opendj/env.sh

configure() {
      # If the instance data does not exist we need to run setup.
    if [ ! -d ./data/db ] ; then
      echo "Instance data Directory is empty. Creating new DJ instance"
      BOOTSTRAP="${BOOTSTRAP:-/opt/opendj/bootstrap/setup.sh}"
      # DS setup complains if the directory is not empty.
      echo "Running $BOOTSTRAP"
      "${BOOTSTRAP}"
    fi
}

start() {

    # todo: Check /opt/opendj/data/config/buildinfo
    # Run upgrade if the server is older

    echo "Starting OpenDJ"

    # Remove any bootstrap sentinel created by setup.
    rm -f /opt/opendj/BOOTSTRAPPING

    # If there is a ./data directory present, create sym links for any top level directories.
    # todo: When commons configuration lands, we should modify config.ldif to point to the directory locations.
    if [ -d data/db ]; then
        for d in data/*
        do
            ln -s $d
        done
    fi

    if [ -d "${SECRET_PATH}" ]; then
      echo "Secret path is present. Will copy any keystores and truststore"
      # We send errors to /dev/null in case no data exists.
      cp -f ${SECRET_PATH}/key*   ${SECRET_PATH}/trust* ./config 2>/dev/null
    fi

    echo "Server id $SERVER_ID"

    exec ./bin/start-ds --nodetach
}

CMD="${1:-run}"

echo "Command is $CMD"


case "$CMD" in
run)
    # Configure (if configuration does not already exist), and then start
    # This is the default action.
    configure
    start
    ;;
configure)
    # Configure only
    configure
    ;;
start)
    # Start only. Will fail if there is no configuration
    start
    ;;
run-post-setup-job)
    /opt/opendj/bootstrap/post-setup-job.sh
    ;;
*)
    exec "$@"
esac