#!/bin/bash

# Source Qubes library.
# shellcheck source=init/functions
. /usr/lib/qubes/init/functions

set -e

/usr/lib/qubes/init/setup-rwdev.sh
if [ -e /dev/xvdb ] ; then mount /rw ; fi
/usr/lib/qubes/init/setup-rw.sh

if is_custom_persist_enabled; then
  mount_home=false
  mount_usr_local=false

  while read -r qubes_persist_entry; do
    [ -z "${qubes_persist_entry}" ] && continue
    mount_point="$(qubesdb-read /persist/"${qubes_persist_entry}")"
    [ "$mount_point" = "/home" ] && mount_home=true
    [ "$mount_point" = "/usr/local" ] && mount_usr_local=true
  done <<< "$(qubesdb-list /persist/)"
else
  mount_home=true
  mount_usr_local=true
fi

if $mount_home; then
  initialize_home "/rw/home" ifneeded
  under_systemd || mount -o noauto,bind,defaults,nosuid,nodev /rw/home /home
else
  under_systemd && disable_persistent_home
  initialize_home "/home" unconditionally
fi

if $mount_usr_local; then
  under_systemd || mount -o noauto,bind,defaults /rw/usrlocal /usr/local
else
  under_systemd && disable_persistent_usrlocal
fi

under_systemd && systemctl daemon-reload || exit 0
