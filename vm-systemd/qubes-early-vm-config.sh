#!/bin/bash

# This is invoked by qubes-early-vm-config.service.
# It happens after local-fs.target is reached
# but before sysinit.target is reached.

for rc in /rw/config/rc.local-early.d/*.rc /rw/config/rc.local-early; do
    [ -f "$rc" ] || continue
    [ -x "$rc" ] || continue
    "$rc"
done
unset rc

# Source Qubes library.
# shellcheck source=init/functions
. /usr/lib/qubes/init/functions

# Set the hostname
if ! is_protected_file /etc/hostname ; then
    name=$(qubesdb-read /name)
    if [ -n "$name" ]; then
        hostname "$name"
        if [ -e /etc/debian_version ]; then
            ipv4_localhost_re="127\.0\.1\.1"
        else
            ipv4_localhost_re="127\.0\.0\.1"
        fi
        sed -i "s/^\($ipv4_localhost_re\(\s.*\)*\s\).*$/\1${name}/" /etc/hosts
        sed -i "s/^\(::1\(\s.*\)*\s\).*$/\1${name}/" /etc/hosts
    fi
fi

# Set the timezone
if ! is_protected_file /etc/timezone ; then
    timezone=$(qubesdb-read /qubes-timezone 2> /dev/null)
    if [ -n "$timezone" ]; then
        ln -sf ../usr/share/zoneinfo/"$timezone" /etc/localtime
        if [ -e /etc/debian_version ]; then
            echo "$timezone" > /etc/timezone
        elif test -d /etc/sysconfig ; then
            echo "# Clock configuration autogenerated based on Qubes dom0 settings" > /etc/sysconfig/clock
            echo "ZONE=\"$timezone\"" >> /etc/sysconfig/clock
        fi
    fi
fi
