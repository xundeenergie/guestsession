#!/bin/bash

ACTION=$1
shift

_UNAME="$@"
echo "USERNAME ${_UNAME}"
_USERNAME=$(echo "${_UNAME}"|tr '[:upper:]' '[:lower:]'|sed -e 's/  *//g' )
_UID=''

check () {
    _UID=$(/usr/bin/id -u "$1" 2>/dev/null)
    if test $? -eq 0 ; then
        echo $_UID
        return 0
    fi
    return 1
}

create () {
    echo $@
    if [ $# -eq 2 ]; then
        echo "Create User"
        /usr/sbin/adduser --no-create-home --gecos "$2" --disabled-password "$1"
        _UID=$(check "$1")
        /usr/bin/passwd -d "$1"
        /bin/systemctl enable guest-home@${_UID}.service
        return 0
    else
        return 2
    fi
}

delete () {
    if [ $# -eq 1 ]; then
        echo "delete $1 $2"
        _UID=$(check "$1")
        /bin/loginctl kill-user "$1"
        /bin/systemctl disable guest-home@${_UID}.service
        /usr/sbin/deluser --remove-home "$1"
        return 0
    else
        return 3
    fi
}

case $ACTION in
    create)
        check $_USERNAME || \
        create "$_USERNAME" "$_UNAME" 
        ;;
    delete)
        check $_USERNAME && \
        delete "$_USERNAME" 
        ;;
    *)
        echo "Wrong call for guestsesseion"
        exit 4
        ;;
esac

exit $?
