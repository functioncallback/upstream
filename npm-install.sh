#!/bin/sh
npm install
rm -rf node_modules/session.socket.io
ln -s ../../session.socket.io/ node_modules/session.socket.io
