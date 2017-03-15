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

[Unit]
Description=Create guest-user (%i) and activate volatile $HOME for it

[Service]
RemainAfterExit=true
ExecStartPre=/bin/sh -c '/bin/systemctl set-environment UNAME=$(echo %i|tr '[:upper:]' '[:lower:]' )'
#ExecStartPre=-/usr/sbin/deluser --remove-home $UNAME
ExecStartPre=-/usr/sbin/adduser --no-create-home --gecos "%i" --disabled-password $UNAME 
ExecStartPre=/bin/sh -c '/bin/systemctl set-environment GUESTUID=$(/usr/bin/id -u $UNAME )'
ExecStartPre=/usr/bin/passwd -d $UNAME
#ExecStartPre=/bin/sh -c '/bin/systemctl daemon-reload'
#ExecStart=/bin/echo $GUESTUID
ExecStart=/bin/sh -c "/bin/systemctl enable guest-home@$GUESTUID.service"
ExecStop=/bin/loginctl kill-user $UNAME
ExecStopPost=/bin/sh -c "/bin/systemctl disable guest-home@$GUESTUID.service"
ExecStopPost=-/usr/sbin/deluser --remove-home $UNAME

[Install]
WantedBy=basic.target
