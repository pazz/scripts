#!/bin/bash
# file: pullmail.sh
#
# This script may be called via a cron job to allow
# offlineimap (and imapfilter) to use the environmental
# variables to access from gnome-keyring
#
# Attaches the current BASH session to a GNOME keyring daemon
#
# Returns 0 on success 1 on failure.
#
# Example cron call: (change the times to suit)
#
# * * * * * /home/pazz/bin/pullmail.sh > /home/pazz/.pullmail.log
# * * * * * sleep 30;/home/pazz/bin/pullmail.sh > /home/pazz/.pullmail.log
#
function gnome-keyring-control() {
        local -a vars=( \
                DBUS_SESSION_BUS_ADDRESS \
                GNOME_KEYRING_CONTROL \
                GNOME_KEYRING_PID \
                XDG_SESSION_COOKIE \
                GPG_AGENT_INFO \
                SSH_AUTH_SOCK \
        )
        local pid=$(ps -C awesome -o pid --no-heading)
        eval "unset ${vars[@]}; $(printf "export %s;" $(sed 's/\x00/\n/g' /proc/${pid//[^0-9]/}/environ | grep $(printf -- "-e ^%s= " "${vars[@]}")) )"
}

gnome-keyring-control

/usr/bin/offlineimap -c /home/pazz/.offlineimaprc -o -u Noninteractive.Basic
/usr/local/bin/notmuch new
/home/pazz/bin/sort_mail.py

