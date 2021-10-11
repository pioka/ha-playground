#!/bin/sh

yum install -y lvm2
systemctl start firewalld && systemctl enable firewalld
