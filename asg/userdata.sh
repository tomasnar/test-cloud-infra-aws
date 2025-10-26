#!/bin/bash -v
dnf update -y
dnf install -y nginx > /tmp/nginx.log
