#!/bin/bash
#
#############################################################################
#############################################################################
#
# libx.sh: initializes script environment
#
#############################################################################
#
# Copyright 2007-2011 Douglas McClendon <dmc AT filteredperception DOT org>
#
#############################################################################
#
# This file is part of X.
#
#    X is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    X is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with X.  If not, see <http://www.gnu.org/licenses/>.
#
#############################################################################
# note: if you'd like a different license, just let me know which and why
#############################################################################


#############################################################################
#############################################################################
##
##
## libx.sh: common system environment, meant to be sourced early
##
##
## DESCRIPTION
##
## libx.sh is just a centralized entrypoint into a set of shared bash scripts
## and libraries.

# TODO: perhaps rename to libxlog.sh since status logging is the core feature
# TODO: x_eval wrapper for logging (ala viros' 'veva' function), i.e. so that
#   you can simply prefix typical processing commands with the wrapper, and
#   then if the user is interested in debugging, they will see all debugging
#   output in realtime and placed in convenient logfiles either way.

#############################################################################
##
## sanity checks: these must be defined before sourcing libx.sh
##
if [ "${x_toolname}" == "" ]; then
    echo "$0: error: fatal: x_toolname is not defined"
    exit 1
fi
if [ "${x_prefix}" == "" ]; then
    echo "$0: error: fatal: x_prefix is not defined"
    exit 1
fi


#############################################################################
##
## get runtime environment
##
starttime="$( date +%Y-%m-%d--%H-%M-%S )"
rundir="$( pwd )"
progname="$( basename $0 2> /dev/null )"
progdir=$( ( pushd $( dirname $( readlink -e "${0}" ) ) > /dev/null 2>&1 ; \
    pwd ; popd > /dev/null 2>&1 ) )
rundir=$( pwd )
mypid=$$


#############################################################################
##
## explicitly set tmpdir to default if not set
##
if [ "${TMPDIR}" == "" ]; then
    export TMPDIR="/tmp"
fi


#############################################################################
##
## load libraries
##
if [ -f "${progdir}/../../tools/scripts/libx.sh" ]; then
    x_devenv=1
    x_devdir=$( ( pushd "${progdir}/../.." > /dev/null 2>&1 ; \
	pwd ; popd > /dev/null 2>&1 ) )
    x_libdir="${x_devdir}/tools/scripts"
    export PATH="${x_devdir}/tools/bin:${x_devdir}/tools/scripts:${PATH}"
elif [ -f "/el-build-workarea/outroot/devtree/Ascendos/tools/scripts/libx.sh" ]; then
    x_devenv=1
    x_devdir=/el-build-workarea/outroot/devtree/Ascendos
    x_libdir="${x_devdir}/tools/scripts"
    export PATH="${x_devdir}/tools/bin:${x_devdir}/tools/scripts:${PATH}"
elif [ -f "${x_prefix}/lib/${x_toolname}/scripts/libx.sh" ]; then
    # TODO: actually support and test this case.  
    # - need toplevel 'make sources' and 'make rpm' etc...
    x_devenv=0
    x_libdir="${x_prefix}/lib/${x_toolname}"
    export PATH="${x_prefix}/lib/${x_toolname}/scripts:${PATH}"
else
    echo "${progname}: fatal error trying to find and load libx.sh library"
    exit 1
fi


#############################################################################
##
## get/set configuration options/variables
##

# source/set package configuration defaults 
source "${x_libdir}/defaults"

# source/set local tree configuration overrides if they exist
if [ -f "${x_libdir}/localconfig" ]; then
    source "${x_libdir}/localconfig"
fi

# source/set local user configuration overrides if they exist
if [ -f "${HOME}/.el-build/config" ]; then
    source "${HOME}/.el-build/config"
fi


#############################################################################
##
## common library code
##

# import common functions
source "${x_libdir}/functions"

# source common script
source "${x_libdir}/common"


#############################################################################
## end script - only notes below
#############################################################################
#
#
#
