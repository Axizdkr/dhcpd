#!/bin/sh

set -e


# Single argument to command line is interface name
if [ $# -eq 1 -a -n "$1" ]; then
    # skip wait-for-interface behavior if found in path
    if ! which "$1" >/dev/null; then
        # loop until interface is found, or we give up
        NEXT_WAIT_TIME=1
        until [ -e "/sys/class/net/$1" ] || [ $NEXT_WAIT_TIME -eq 4 ]; do
            sleep $(( NEXT_WAIT_TIME++ ))
            echo "Waiting for interface '$1' to become available... ${NEXT_WAIT_TIME}"
        done
        if [ -e "/sys/class/net/$1" ]; then
            IFACE="$1"
        fi
    fi
fi

# No arguments mean all interfaces
if [ -z "$1" ]; then
    IFACE=" "
fi

if [ -n "$IFACE" ]; then
    # Run dhcpd for specified interface or all interfaces

    data_dir="/data"
    if [ ! -d "$data_dir" ]; then
        echo "Please ensure '$data_dir' folder is available."
        echo 'If you just want to keep your configuration in "data/", add -v "$(pwd)/data:/data" to the docker run command line.'
        exit 1
    fi

    dhcpd_conf="$data_dir/dhcpd.conf"
    if [ ! -r "$dhcpd_conf" ]; then
        echo "Please ensure '$dhcpd_conf' exists and is readable."
        echo "For info, please visit https://kb.isc.org/docs/isc-dhcp-44-manual-pages-dhcpdconf"
        exit 1
    fi

    uid=$(stat -c%u "$data_dir")
    gid=$(stat -c%g "$data_dir")
    if [ $gid -ne 0 ]; then
        groupmod -g $gid dhcp
    fi
    if [ $uid -ne 0 ]; then
        usermod -u $uid dhcp
    fi

    [ -e "$data_dir/dhcpd.leases" ] || touch "$data_dir/dhcpd.leases"
    chown dhcp:dhcp "$data_dir/dhcpd.leases"
    if [ -e "$data_dir/dhcpd.leases~" ]; then
        chown dhcp:dhcp "$data_dir/dhcpd.leases~"
    fi

    $run /usr/sbin/dhcpd -4 -f -d --no-pid -cf "$data_dir/dhcpd.conf" -lf "$data_dir/dhcpd.leases" $IFACE
else
    # Run another binary
    $run "$@"
fi
