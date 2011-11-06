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

##
## get runtime environment
##
starttime="$( date +%Y-%m-%d--%H-%M-%S )"
rundir="$( pwd )"
progname="$( basename $0 )"
progdir=$( ( pushd $( dirname $( readlink -e "${0}" ) ) > /dev/null 2>&1 ; \
    pwd ; popd > /dev/null 2>&1 ) )
rundir=$( pwd )
mypid=$$

##
## explicitly set tmpdir to default if not set
##
if [ "${TMPDIR}" == "" ]; then
    export TMPDIR="/tmp"
fi

##
## load libraries
##
if [ -f "${progdir}/../../tools/scripts/libx.sh" ]; then
    source "${progdir}/../../tools/scripts/defaults"
    source "${progdir}/../../tools/scripts/functions"
    source "${progdir}/../../tools/scripts/common"
    x_devenv=1
    x_devdir=$( ( pushd "${progdir}/../.." > /dev/null 2>&1 ; \
	pwd ; popd > /dev/null 2>&1 ) )
    export PATH="${x_devdir}/tools/bin:${x_devdir}/tools/scripts:${PATH}"
elif [ -f "/root/output/devtree/Ascendos/tools/scripts/libx.sh" ]; then
    # sad sad tired workaround.  Better to somehow run v-bake as v-bake
    # within the extracted full devtree (with options passing)
    source  "/root/output/devtree/Ascendos/tools/scripts/defaults"
    source  "/root/output/devtree/Ascendos/tools/scripts/functions"
    source  "/root/output/devtree/Ascendos/tools/scripts/common"
    source  "/tmp/v-bake.options"
    x_devenv=1
    x_devdir=/root/output/devtree/Ascendos
    export PATH="${x_devdir}/tools/bin:${x_devdir}/tools/scripts:${PATH}"
elif [ -f "${x_prefix}/lib/${x_toolname}/scripts/libx.sh" ]; then
    source  "${x_prefix}/lib/${x_toolname}/scripts/defaults"
    source  "${x_prefix}/lib/${x_toolname}/scripts/functions"
    source  "${x_prefix}/lib/${x_toolname}/scripts/common"
    x_devenv=0
    x_libdir="${x_prefix}/lib/${x_toolname}"
    export PATH="${x_prefix}/lib/${x_toolname}/tools/bin:${x_prefix}/lib/${x_toolname}/tools/scripts:${PATH}"
else
    echo "${progname}: fatal error trying to find and load libx.sh library"
    exit 1
fi

#############################################################################
#############################################################################
#############################################################################
#############################################################################
