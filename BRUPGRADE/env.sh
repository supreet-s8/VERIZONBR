#!/bin/bash
# Guavus Tools Package 
# Copyright 2014 Guavus Network Systems Ltd.
# 
#
# Env setup 
# Covers Tall Maple 2.x
#

# 
SSHTIMEOUT=5
ROOTUSER='root'

# GGN LAB
gdsvzbcol1=108.55.163.56
gdsvzbcol2=108.55.163.26
gdsvzbcmp1=108.55.163.41
gdsvzbcmp2=108.55.163.42
gdsvzbcmp3=108.55.163.43
gdsvzbcmp4=108.55.163.44
gdsvzbcmp5=108.55.163.45
gdsvzbcmp6=108.55.163.46
gdsvzbcmp7=108.55.163.57
gdsvzbcmp8=108.55.163.58
gdsvzbcmp9=108.55.163.59
gdsvzbcmp10=108.55.163.63
gdsvzbcmp11=108.55.163.66
gdsvzbcmp12=108.55.163.67
gdsvzbcmp13=108.55.163.68
gdsvzbins1=108.55.163.60
gdsvzbins2=108.55.163.29
gdsvzbinsnew1=108.55.163.91
gdsvzbinsnew2=108.55.163.92
gdsvzbrge1=108.55.163.70
gdsvzbrge2=108.55.163.31
gdsvzbrub1=108.55.163.85
gdsvzbrub2=108.55.163.86
gdsvzbrub3=108.55.163.87
gdsvzbrub4=108.55.163.88
gdsvzbrub5=108.55.163.89
gdsvzbrub6=108.55.163.90
gdsvzbcolvip=108.55.163.75
gdsvzbinsnewvip=108.55.163.93
gdsvzbinsvip=108.55.163.76
gdsvzbrubvip=108.55.163.77
gdsvzbrgevip=108.55.163.84

# Binaries/Aliases
SSH="/usr/bin/ssh -q -o ConnectTimeout=${SSHTIMEOUT} -l ${ROOTUSER} "

# CLI Commands
CLI='/opt/tms/bin/cli'

# PMX Commands
PMX='/opt/tps/bin/pmx.py'

#HADOOP
HADOOP=/opt/hadoop/bin/hadoop
