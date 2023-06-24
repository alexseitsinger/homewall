#!/bin/sh -

_main() {
  local SRC_DIR='/work/systems/targets/homewall';
  local BASTILLE_ROOT='/usr/local/bastille/jails/dev0/root';
  local DST_DIR="${BASTILLE_ROOT}${SRC_DIR}";

  #/sbin/mount -t nullfs -o rw ${SRC_DIR} ${DST_DIR} || return 1
  /sbin/mount -t nullfs -o rw ${SRC_DIR}/mnt ${DST_DIR}/mnt || return 1
  /sbin/mount -t nullfs -o rw ${SRC_DIR}/files ${DST_DIR}/mnt/files || return 1
  /sbin/mount -t nullfs -o rw ${SRC_DIR}/mnt/var ${DST_DIR}/mnt/var || return 1
  /sbin/mount -t nullfs -o rw ${SRC_DIR}/mnt/usr/local ${DST_DIR}/mnt/usr/local || return 1
  /sbin/mount -t nullfs -o rw ${SRC_DIR}/mnt/home ${DST_DIR}/mnt/home || return 1
}
_main;
