#!/bin/bash -u

echo "Start swupdate daemon."
USTATE=$(fw_printenv -n ustate)
case $USTATE in
    0) CONFIRM="" ;;
    2) fw_setenv ustate 0; CONFIRM="-c 2" ;;
    3) CONFIRM="-c 3" ;;
    *) echo "Unsupported ustate value. Use 0 instead."; CONFIRM="" ;;
esac
/usr/bin/swupdate -f /etc/swupdate.cfg -u "$CONFIRM"
