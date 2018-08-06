#!/bin/sh
kernel=`uname -s`
case $kernel in
    Linux | linux)
	# Try to find out which libc is in use
	libc=`ldd --version 2>&1 | head -n 1`
	case $libc in
	    *GLIBC*)
		echo 'linux-glibc'
		;;
	    *musl*)
		echo 'linux-musl'
		;;
	    *)
		echo 'linux-unknown'
		;;
	    esac
	;;
    Darwin | darwin)
	# Test for MacOS
	product=`sw_vers -productName`
	case $product in
	    mac* | Mac*)
		echo 'macos'
		;;
	    *)
		echo 'darwin'
		;;
	    esac
	;;
    *)
	echo 'unknown'
	;;
esac
