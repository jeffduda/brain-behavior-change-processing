#!/bin/bash
# ---------------------------------------------------------------
# TRANPOSE_TEXTFILE.SH
# Wrapper for AFNI python script that does this
#
# Created: M Elliott 5/2014
# ---------------------------------------------------------------

Usage() {
    echo "" >&2
    echo "Usage: `basename $0` infile outfile" >&2
    echo "" >&2
    exit 1
}

if [ $# -ne 2 ]; then
    Usage
fi

# find location of AFNI programs
tmp=`which afni`
afnipath=`dirname $tmp`

# crazy problem with BBL alias for python location (non-interactive BASH scripts don't expand aliases!)
#tmp=`which python`
#n=${#tmp[@]}
#python_cmd=${tmp[$n-1]}
shopt -s expand_aliases
source /etc/bashrc

python ${afnipath}/1d_tool.py -infile $1 -transpose -write $2 -overwrite
exit $?
