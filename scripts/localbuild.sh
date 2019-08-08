#!/bin/bash

# Quit on error
set -e

##############################################
# THIS FILE IS USED TO RUN LOCAL SITE BUILDS #
##############################################

# Requirements:
# (1) HUGO installed
# (2) Local builds require both the knative/website and knative/docs repos
#     cloned into the same folder on your local machine.
#
# USAGE:
# From the root of the knative/website clone, run:
#
#   scripts/localbuild.sh
#
# By default, the command locally runs a Hugo build of your knative/website and
# knative/docs clones (including any local changes).
#
# You can also build and preview changes in other Forks and Branches.
# See details about optional settings and flags below.

LOCALBUILD="true"

# Retrieve the default docs version
source scripts/docs-version-settings.sh
# Use default repo and branch from docs-version-settings.sh
BRANCH="$DEFAULTBRANCH"
FORK="$DEFAULTFORK"

# OPTIONS:
#
# (1) Override the default repo, branch, or both for your local builds/testing.
#     These settings clone from the defined repo and branch, and then locally
#     build those docs to allow you to locally preview changes from remote
#     forks/branches.
#
#     USAGE: Append the -f repofork and/or the -b branchname to the command.
#            Example:
#                    ./scripts/build.sh -f repofork -b branchname
#
# (2) Run a complete local build of the knative.dev site. Clones all the content
#     from the remote repo, including all docs releases.
#
#     USAGE: Append the -a true to the command.
#            Example:
#                    ./scripts/build.sh -a true
#
#
# Examples:
#  - Default local build:
#    ./scripts/build.sh
#
#  - Clone all docs releases from knative/docs and then run local build:
#    ./scripts/build.sh -a true
#
#  - Locally build content from remote repo:
#    ./scripts/build.sh -f repofork -b branchname
#
#  - Locally build all versions from remote repo ():
#    ./scripts/build.sh -f  -b branchname -a true
#
while getopts f:b:a: arg; do
  echo '------ BUILDING DOCS FROM: ------'
  case $arg in
    f)
      echo "${OPTARG}" 'FORK'
      # Set GitHub repo, where your knative/docs fork exist
      FORK="${OPTARG}"
      ;;
    b)
      echo "${OPTARG}" 'BRANCH'
      # Set the name of the remote branch in your knative/docs fork
      BRANCH="${OPTARG}"
      ;;
    a)
      echo 'BUILDING ALL RELEASES FROM REMOTE'
      # If 'true', all knative/docs branches from the specified fork ($FORK)
      # are built. REQUIRED: All branches must exist in the specified $FORK and
      # the names of each branch must match the branches in the knative/docs
      # repo ('release-0.X'). For example: 'release-0.7', 'release-0.6', etc...
      BUILDALLRELEASES="${OPTARG}"
      ;;
  esac
done

source scripts/processsourcefiles.sh

# BUILD MARKDOWN
# Start HUGO build
hugo server -b ""
