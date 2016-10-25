#!/bin/sh
#
# Use `ulibTestsLinux/test_crypto' to test UMCrypto.m

set -e

echo "starting Universal Crypto Linux tests"

ulibTestsLinux/test_crypto > check_crypto.log 2>&1
ret=$?

if [ "$ret" != 0 ]
then
        echo check_crypto failed 1>&2
        echo See check_crypto.log 1>&2
        exit 1
fi

rm -f check_crypto.log
