#!/bin/sh

if [ -e /etc/os-release ] ; then
    exec perl -lne 'if (/PRETTY_NAME=\"(.*)\"$/) { print $1; }' /etc/os-release
fi

for i in /etc/centos-release /etc/fedora-release /etc/redhat-release ; do
    if [ -e "$i" ] ; then
	exec cat "$i"
    fi
done

if [ -e /etc/lsb-release ] ; then
    exec printf "%s (%s)\n" "`lsb_release -s -d`" "`lsb_release -s -c`"
fi

false
