#!/bin/bash

#create or delete volatile homedir for a guest-session depending wheter btrfs is available or not.
BTRFS="/bin/btrfs"
RSYNC="/usr/bin/rsync"
MKDIR="/bin/mkdir"
RM="/bin/rm"

check_btrfs () {
	FS=$(stat -f --format=%T "$1")
	if [ "$FS" = "btrfs" ]; then
		return 0
	else
		return 1
	fi
}

check_btrfs_subvolume () {
	FS=$(stat --format=%i "$1")
	if [ $FS -eq 256 ]; then
		return 0
	else
		return 1
	fi
}


delete_home () {
	echo "delete home $DST"
	if [ -d "$DST" ]; then
		if check_btrfs_subvolume "$DST"; then
			$BTRFS subvolume delete -c "$DST"
		else
			$RM -rf "$DST"
		fi
	fi
}

create_home () {
	echo "XXX $UID $SRC $DSTDIR $DST"
	if check_btrfs "$SRC"; then
		if check_btrfs "$DSTDIR"; then
			if check_btrfs_subvolume "$SRC"; then
				$BTRFS subvolume snapshot "$SRC" "$DST"
			else
				$BTRFS subvolume create "$DST"
				$RSYNC -a "$SRC/" "$DST"
			fi
		else
			$MKDIR "$DST"
			$RSYNC -a "$SRC/" "$DST"
		fi
	else
		if check_btrfs "$DST"; then
			$BTRFS subvolume create "$DST"
		else
			$MKDIR "$DST"
		fi
		$RSYNC -a "$SRC/" "$DST"
	fi
}

create_skel () {
	SRC="/etc/skel"
	DST=$1
	DSTDIR=$(dirname $2)
	echo "Check skel $UID $SRC $DSTDIR $DST"
	if [ -d "$DST" ]; then
		return 0
	else
		if check_btrfs "$SRC"; then
			if check_btrfs "$DSTDIR"; then
				if check_btrfs_subvolume "$SRC"; then
					$BTRFS subvolume snapshot "$SRC" "$DST"
				else
					$BTRFS subvolume create "$DST"
					$RSYNC -a "$SRC/" "$DST"
				fi
			else
				$MKDIR "$DST"
				$RSYNC -a "$SRC/" "$DST"
			fi
		else
			if check_btrfs "$DST"; then
				$BTRFS subvolume create "$DST"
			else
				$MKDIR "$DST"
			fi
			$RSYNC -a "$SRC/" "$DST"
		fi
	fi
}

while :
do
	case $1 in
		create)
			shift
			export SRC="$(dirname "$1")/$(basename "$1")"
			export DST="$(dirname "$2")/$(basename "$2")"
			export DSTDIR="$(dirname $DST)"
			create_skel "$DST"
			delete_home 
			create_home 
			break
			;;
		delete)
			shift
			export DST="$(dirname "$1")/$(basename "$1")"
			export DSTDIR="$(dirname $DST)"
			delete_home 
			break
			;;
		*)
			exit 1
	esac
done


