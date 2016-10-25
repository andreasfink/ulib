#!/bin/sh
#
# Use `ulibTestsLinux/test_socket' to test UMSocket.m

set -e

echo "starting Universal Socket Linux tests"

ulibTestsLinux/test_socket > check_socket.log 2>&1
ret=$?

if [ "$ret" != 0 ]
then
        echo check_socket failed 1>&2
        echo See check_socket.log 1>&2
        exit 1
fi

rm -f check_socket.log
