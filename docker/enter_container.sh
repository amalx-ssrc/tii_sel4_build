#!/usr/bin/env bash

#set -x

# Find utility functions
SCRIPT_DIR="$(dirname $(realpath $0))/../../scripts"
. "${SCRIPT_DIR}"/utils.sh


# Variables
WORKSPACE_ROOT=
CENGINE=
CIMAGE=

[[ "$#" -lt 3 ]] && die "Too few arguments!"

# Parse and check needed args
WORKSPACE_ROOT="$1"
CENGINE="$2"
CIMAGE="$3"
shift 3
[[ -e "${WORKSPACE_ROOT}" ]] || die "Workspace root \"${WORKSPACE_ROOT}\" doesn't exist!"
[[ -z "${CENGINE}" ]] && die "Unknown container engine!"
[[ -z "${CIMAGE}" ]] && die "Unknown container image!"

# Check if are given a program to run
CEXEC="$*"
[[ -z "${CEXEC}" ]] && CEXEC="/bin/bash"


# Container args
CARGS=

# Support for non-terminal runs
[[ -t 0 ]] && CARGS+="-it"

# Basic args
CARGS+=" --rm"
CARGS+=" --hostname tiiuae-build"
CARGS+=" -v ${HOME}/.gitconfig:/home/$(id -un)/.gitconfig"

# Container engine specific flags
if [[ "${CENGINE}" -eq "podman" ]]; then
  CARGS+=" --userns=keep-id"
else
  CARGS+=" -u $(id -u):$(id -g)"
fi

if [[ -e "${SSH_AUTH_SOCK}" ]]; then

  auth_sock=

  if [[ -L "${SSH_AUTH_SOCK}" ]]; then
    # Is a link file
    auth_sock="$(readlink -f "${SSH_AUTH_SOCK}" 2>/dev/null)"
    auth_sock="$(realpath "${auth_sock}")"
  else
    # Else normal file
    auth_sock="$(realpath "${SSH_AUTH_SOCK}")"
  fi

  if [[ -n "${auth_sock}" ]]; then
    CARGS+=" -v ${auth_sock}:/ssh-agent"
    CARGS+=" -e SSH_AUTH_SOCK=/ssh-agent"
  fi
fi

# Run or die
${CENGINE} run \
  ${CARGS} \
  -e CENGINE=${CENGINE} \
  -e IN_CONTAINER=true \
  -v ${WORKSPACE_ROOT}:/workspace:z \
  ${CIMAGE} \
  ${CEXEC}
