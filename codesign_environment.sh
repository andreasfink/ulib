#!/bin/bash

if [ "${APPLICATION_CERT}" == "" ]
then
	export XCODESIGN='CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO'
else
	export XCODESIGN='CODE_SIGNN_IDENTITY="'"$APPLICATION_CERT"'"'
fi

if [ "${INSTALLER_CERT}" == "" ]
then
	export PKG_SIGN=""
else
	export PKG_SIGN='--sign "'"$INSTALLER_CERT"'"'
fi

