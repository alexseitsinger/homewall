#!/bin/sh -

builtin . /etc/shrc;

_add_top() {
  local TARGET_DIR="$1";

  # attach and mount the base image.
  local TOP_IMG="${TARGET_DIR}/images/top";
  local TOP_DEV=$( attach "$TOP_IMG" );
  local TOP_DIR=$( /usr/bin/dirname $( /usr/bin/dirname $( /bin/realpath "$TOP_IMG" )))
  if ! is-mounted "$TOP_DEV"; then
    /sbin/mount "$TOP_DEV" "${TOP_DIR}/mnt" || return 1
  fi
  # mount the base into the target.
  if ! is-mounted "${TARGET_DIR}/mnt"; then
    /sbin/mount -t nullfs -o rw ${TOP_DIR}/mnt ${TARGET_DIR}/mnt || return 1
  fi
}

_add_var() {
  local TARGET_DIR="$1";

  # attach and mount var img
  local VAR_IMG="${TARGET_DIR}/images/var";
  local VAR_DEV=$( attach "$VAR_IMG" );
  if ! is-mounted "$VAR_DEV"; then
    /sbin/mount "$VAR_DEV" "${TARGET_DIR}/mnt/var" || return 1
  fi
}

_add_usr_local() {
  local TARGET_DIR="$1";

  # attach and mount /usr/local image
  local USR_LOCAL_IMG="${TARGET_DIR}/images/usr_local";
  local USR_LOCAL_DEV=$( attach "$USR_LOCAL_IMG" );
  if ! is-mounted "$USR_LOCAL_DEV"; then
    /sbin/mount "$USR_LOCAL_DEV" "${TARGET_DIR}/mnt/usr/local" || return 1
  fi
}

_add_home() {
  local TARGET_DIR="$1";

  # attach and mount /home image.
  local HOME_IMG="${TARGET_DIR}/images/home";
  local HOME_DEV=$( attach "$HOME_IMG" );
  if ! is-mounted "$HOME_DEV"; then
    /sbin/mount "$HOME_DEV" "${TARGET_DIR}/mnt/home" || return 1
  fi
}

_add_files() {
  local TARGET_DIR="$1";

  # mount /files into target.
  local FILES_SRC="${TARGET_DIR}/files";
  local FILES_DST="${TARGET_DIR}/mnt/files";
  if ! is-mounted "$FILES_DST"; then
    /sbin/mount -t nullfs -o rw "$FILES_SRC" "$FILES_DST" || return 1
  fi
}

_start() {
  local TARGET_DIR=$( /usr/bin/dirname $( /bin/realpath "$0" ));
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory was not found"; return 1;
  fi

  _add_top "$TARGET_DIR" || return 1
  _add_var "$TARGET_DIR" || return 1
  _add_home "$TARGET_DIR" || return 1
  _add_usr_local "$TARGET_DIR" || return 1
  _add_files "$TARGET_DIR" || return 1
}

_remove_top() {
  local TARGET_DIR="$1";

  # 5. unmount and detach top.
  local TOP_IMG="${TARGET_DIR}/images/top";
  local TOP_DEV=$( attach "$TOP_IMG" );
  local TOP_DIR=$( /usr/bin/dirname $( /usr/bin/dirname $( /bin/realpath "$TOP_IMG" )))
  if is-mounted "${TARGET_DIR}/mnt"; then
    /sbin/umount "${TARGET_DIR}/mnt" || return 1
  fi
  if is-mounted "${TARGET_DIR}/mnt"; then
    /sbin/umount "${TARGET_DIR}/mnt" || return 1
  fi
  if is-attached "$TOP_IMG"; then
    detach "$TOP_IMG" || return 1
  fi
}

_remove_var() {
  local TARGET_DIR="$1";

  # 4. detach and unmount /var.
  local VAR_IMG="${TARGET_DIR}/images/var";
  local VAR_DEV=$( attach "$VAR_IMG" );
  if is-mounted "$VAR_DEV"; then
    /sbin/umount "$VAR_DEV" || return 1
  fi
  if is-attached "$VAR_IMG"; then
    detach "$VAR_IMG" || return 1
  fi
}

_remove_usr_local() {
  local TARGET_DIR="$1";

  # 3. detach and unmount /usr/local image
  local USR_LOCAL_IMG="${TARGET_DIR}/images/usr_local";
  local USR_LOCAL_DEV=$( attach "$USR_LOCAL_IMG" );
  if is-mounted "$USR_LOCAL_DEV"; then
    /sbin/umount ${TARGET_DIR}/mnt/usr/local || return 1
  fi
  if is-attached "$USR_LOCAL_IMG"; then
    detach "$USR_LOCAL_IMG" || return 1
  fi
}

_remove_home() {
  local TARGET_DIR="$1";

  # 2. detach and unmount /home image.
  local HOME_IMG="${TARGET_DIR}/images/home";
  local HOME_DEV=$( attach "$HOME_IMG" );
  if is-mounted "$HOME_DEV"; then
    /sbin/umount ${TARGET_DIR}/mnt/home || return 1
  fi
  if is-attached "$HOME_IMG"; then
    detach "$HOME_IMG" || return 1
  fi
}

_remove_files() {
  local TARGET_DIR="$1";

  # 1. mount /files into target.
  local FILES_DST="${TARGET_DIR}/mnt/files";
  if is-mounted "$FILES_DST"; then
    /sbin/umount ${FILES_DST} || return 1
  fi
}

_stop() {
  local TARGET_DIR=$( /usr/bin/dirname $( /bin/realpath "$0" ));
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory was not found"; return 1;
  fi

  _remove_files "$TARGET_DIR" || return 1
  _remove_usr_local "$TARGET_DIR" || return 1
  _remove_home "$TARGET_DIR" || return 1
  _remove_var "$TARGET_DIR" || return 1
  _remove_top "$TARGET_DIR" || return 1
}

_umount_out() {
  local TARGET_DIR=$( /usr/bin/dirname $( /bin/realpath "$0" ));
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory was not found"; return 1;
  fi

  local JAIL_NAME="$1";
  if [ -z "$JAIL_NAME" ]; then
    noarg '<$1: JAIL_NAME>'; return 1;
  fi

  # e.g. homewall
  local TARGET_NAME=$( /usr/bin/basename "$TARGET_DIR" );
  # e.g. work/systems/targets/homewall
  local JAIL_PATH=$( echo "$TARGET_DIR" | /usr/bin/grep -soE "^(\/.+)+\/${TARGET_NAME}\/?" | /usr/bin/sed -E 's|^\/||' );
  # e.g. usr/local
  #local REM_PATH=$( echo "$TARGET_DIR" | /usr/bin/sed -E "s|^(\/.+)+\/${TARGET_NAME}(\/mnt)?\/?||g" );

  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH}/mnt/files || return 1
  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH}/mnt/home || return 1
  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH}/mnt/usr/local || return 1
  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH}/mnt/var || return 1
  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH}/mnt || return 1
  sudo bastille umount ${JAIL_NAME} ${JAIL_PATH} || return 1
}

_mount_in() {
  local TARGET_DIR=$( /usr/bin/dirname $( /bin/realpath "$0" ));
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory was not found"; return 1;
  fi

  local JAIL_NAME="$1";
  if [ -z "$JAIL_NAME" ]; then
    noarg '<$1: JAIL_NAME>'; return 1;
  fi

  # e.g. homewall
  local TARGET_NAME=$( /usr/bin/basename "$TARGET_DIR" );
  # e.g. work/systems/targets/homewall
  local JAIL_PATH=$( echo "$TARGET_DIR" | /usr/bin/grep -soE "^(\/.+)+\/${TARGET_NAME}\/?" | /usr/bin/sed -E 's|^\/||' );
  # e.g. usr/local
  #local REM_PATH=$( echo "$TARGET_DIR" | /usr/bin/sed -E "s|^(\/.+)+\/${TARGET_NAME}(\/mnt)?\/?||g" );

  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR} ${JAIL_PATH} nullfs rw 0 0 || return 1
  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR}/mnt ${JAIL_PATH}/mnt nullfs rw 0 0 || return 1
  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR}/mnt/var ${JAIL_PATH}/mnt/var nullfs rw 0 0 || return 1
  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR}/mnt/usr/local ${JAIL_PATH}/mnt/usr/local nullfs rw 0 0 || return 1
  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR}/mnt/home ${JAIL_PATH}/mnt/home nullfs rw 0 0 || return 1
  sudo bastille mount ${JAIL_NAME} ${TARGET_DIR}/mnt/files ${JAIL_PATH}/mnt/files nullfs rw 0 0 || return 1
}

_usage() {
/bin/cat <<-'__EOF__'>>/dev/stderr
manage.sh <CMD> <ARGS>

Commands:
  start: start the bastille jail
  stop: stop the bastille jail
    [start|stop]
  mount-in: mount the filesystem into the running bastille jail.
  umount-out: unmount the filesystem from the running bastille jail.
    [mount-in|umount-out] <JAIL_NAME>
__EOF__
}

_main() {
  local CMD="$1"; shift 1;
  local ARGS="$@";

  case "$CMD" in
    start) _start;;
    stop) _stop;;
    mount-in) _mount_in "$ARGS";;
    umount-out) _umount_out "$ARGS";;
    *) _usage;;
  esac
}
_main "$@";
