#!/bin/bash

#create or delete volatile homedir for a guest-session depending wheter btrfs is available or not.
BTRFS="/bin/btrfs"
RSYNC="/usr/bin/rsync"
MKDIR="/bin/mkdir"
RM="/bin/rm"
CHOWN="/bin/chown"

action=$1
uid=$2
gid=$(/usr/bin/id -g $uid)
skel=/etc/skel
skeldir=$(dirname $skel)
uname=$(/usr/bin/id -u -n $uid)
uskel=/etc/skel${uname}
home=$(getent passwd $uid | cut -d: -f6)
homedir=$(dirname $home)



check_btrfs () {
    FS=$(stat -f --format=%T "$1" 2>/dev/null )
    if [ "$FS" = "btrfs" ]; then
        return 0
    else
        return 1
    fi
}

check_btrfs_subvolume () {
    FS=$(stat --format=%i "$1" 2>/dev/null )
    if [ $FS -eq 256 ]; then
        return 0
    else
        return 1
    fi
}


delete_home () {
    if [ -d "$home" ]; then
        if check_btrfs_subvolume "$home"; then
            $BTRFS subvolume delete -c "$home"
        else
            $RM -rf "$home"
        fi
    fi
    return 0
}

create_home () {
    if check_btrfs "$uskel"; then
        if check_btrfs "$homedir"; then
            if check_btrfs_subvolume "$uskel"; then
                $BTRFS subvolume snapshot "$uskel" "$home"
            else
                $BTRFS subvolume create "$home"
                $RSYNC -a "$uskel/" "$home"
            fi
        else
            $MKDIR "$home"
            $RSYNC -a "$uskel/" "$home"
        fi
    else
        if check_btrfs "$homedir"; then
            $BTRFS subvolume create "$home"
        else
            $MKDIR "$home"
        fi
        $RSYNC -a "$uskel/" "$home"
    fi
    $CHOWN -R ${uid}:${gid} $home
}

create_skel () {
    if [ -d "$uskel" ]; then
        return 0
    else
        if check_btrfs "$skeldir"; then
            if check_btrfs_subvolume "$skel"; then
                $BTRFS subvolume snapshot "$skel" "$uskel"
            else
                $BTRFS subvolume create "$uskel"
                $RSYNC -a "$skel/" "$uskel"
            fi
        else
            $MKDIR "$uskel"
            $RSYNC -a "$skel/" "$uskel"
        fi
    fi
    return 0
}

case $action in
    create)
        create_skel
        delete_home 
        create_home 
        ;;
    delete)
        delete_home 
        ;;
    *)
        exit 1
        ;;
esac
