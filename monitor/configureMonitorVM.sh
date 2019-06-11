#!/bin/sh

apt-get -y update
apt-get -y install python3-pip
pip3 install --upgrade pip==19.1.1
pip3 install pyhdb

