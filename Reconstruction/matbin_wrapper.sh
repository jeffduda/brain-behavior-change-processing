#!/bin/sh
# MATBIN_WRAPPER.sh
# Generic script for calling a compiled Matlab executable
#
# M.Elliott 3/2014

# --- Parse command line ---
if [ $# -lt 1 ]; then
	echo "usage: $0 <executable_file> <args...>"
	exit 1
fi

execname=`basename $1`            # removes any directory in front (leaves extension)
execroot=${execname%.*}           # strips extension
execdir=`dirname "$0"`            
execdir=${execdir}/../matlab_binaries # matlab binaries lives here
shift

# --- find Matlab root folder ---
if [ "X${MCRROOT}" = "X" ]; then 
   if [ -d /import/monstrum/Applications/MATLAB ]; then		# BBL
        MCRROOT=/import/monstrum/Applications/MATLAB/

    elif [ -d /usr/local/MATLAB/R2012b ]; then			# old CfN (e.g.HEFT)
        MCRROOT=/usr/local/MATLAB/R2012b/

     elif [ -d /share/apps/matlab/R2013a ]; then		# new CfN (e.g.CHEAD)
        MCRROOT=/share/apps/matlab/R2013a/

    elif [ -d /usr/local/MATLAB/R2013a ]; then			# Tesla
        MCRROOT=/usr/local/MATLAB/R2013a/

    elif [ -d /opt/matlab_2010b ]; then			# Pedro
        MCRROOT=/opt/matlab_2010b/

    else
        echo "ERROR: don't know how to set MCRROOT folder";
        exit 1
    fi
fi
#echo "Using MCRROOT = $MCRROOT"

# --- Set up environment variables ---
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
export LD_LIBRARY_PATH;
export XAPPLRESDIR;

# --- clean up args ---
args=
while [ $# -gt 0 ]; do
    token=`echo "$1" | sed 's/ /\\\\ /g'`   # Add blackslash before each blank
    args="${args} ${token}" 
    shift
done
  
# --- run the executable ---  
eval ${execdir}/${execroot} $args
status=$?

exit $status

