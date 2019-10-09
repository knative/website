#!/bin/bash

# Quit on error
set -e

##############################################
# THIS FILE IS USED TO RUN LOCAL SITE BUILDS #
##############################################

# USAGE:
# 1. Install Hugo: https://www.docsy.dev/docs/getting-started/#install-hugo
#    If using OSX then install gnu-sed: https://daoyuan.li/a-normal-sed-on-mac/
#
# 2. Optional: Install PostCSS if you want to change the sites CSS and need to build those changes locally.
#    https://www.docsy.dev/docs/getting-started/#install-postcss
#
# 3. Clone the knative/docs repo:
#    `git clone https://github.com/knative/docs.git`
#
# 4. Clone the knative/website repo, including the Docsy theme submodule:
#    `git clone --recurse-submodules https://github.com/knative/website.git`
#
# 5. From the root of the knative/website clone, run:
#    `scripts/localbuild.sh`
#
# 6. If you change content in your knative/docs repo clone, you rebuild your local
#    site by stopping the localhost (CTRL C) and running `scripts/localbuild.sh` again.
#
# By default, the command locally runs a Hugo build of using your local knative/website and
# knative/docs clones (including any local changes).
#
# All files from you local knative/docs clone are copied into the 'content'
# folder of your knative/website repo clone, and then they are processed in the
# same way that they are process on the Netlify host server.
#
# You can also build and preview changes from other remote Forks and Branches.
# See details about optional settings and flags below.

# Retrieve the default docs version
source scripts/docs-version-settings.sh
# Use default repo and branch from docs-version-settings.sh
BRANCH="$DEFAULTBRANCH"
FORK="$DEFAULTFORK"

# Set local build default values
BUILDENVIRONMENT="local"
BUILDALLRELEASES="false"
BUILDSINGLEBRANCH="false"
PRBUILD="false"


# OPTIONS:
#
# (1) Specify a remote repo fork, branch, or both, to build that content locally.
#     The specified repo and branch are cloned and built locally to allow you to
#     preview changes in remote forks and branches.
#
#     USAGE: Append the -f repofork and/or the -b branchname to the command.
#            Example:
#                    ./scripts/build.sh -f repofork -b branchname
#
# (2) Run a complete local build of the knative.dev site. Clones all the content
#     from knative/docs repo, including all branches.
#
#     USAGE: Append the -a true to the command.
#            Example:
#                    ./scripts/build.sh -a true
#
#
# Examples:
#  - Default local build:
#    ./scripts/localbuild.sh
#
#  - Clone all docs releases from knative/docs and then run local build:
#    ./scripts/localbuild.sh -a true
#
#  - Locally build content from specified fork and branch:
#    ./scripts/localbuild.sh -f repofork -b branchname
#
#  - Locally build a specific version from $FORK:
#    ./scripts/localbuild.sh -b branchname 
#
while getopts f:b:a: arg; do
  case $arg in
    f)
	  echo '--- BUILDING FROM ---'
      echo 'FORK:' "${OPTARG}"
      # Build remote content locally
      # Set the GitHub repo name of your knative/docs fork you want built.
      FORK="${OPTARG}"
      # Retrieve content from remote repo
      BUILDSINGLEBRANCH="true"
      ;;
    b)
      echo 'USING BRANCH:' "${OPTARG}"
      # Build remote content locally
      # Set the branch name that you want built.
      BRANCH="${OPTARG}"
      # Retrieve content from remote repo branch
      BUILDSINGLEBRANCH="true"
      ;;
    a)
      echo 'BUILDING ALL RELEASES FROM KNATIVE/DOCS'
      # If 'true', all knative/docs branches are built to mimic a 
      # "production" build. 
      # REQUIRED: If you specify a fork ($FORK), all of the same branches 
      # (with the same branch names) that are built in knative.dev must
      # also exist and be available in the that $FORK (ie, 'release-0.X'). 
      # See /config/production/params.toml for the list of the branches
      # their names that are currently built in knative.dev.
      BUILDALLRELEASES="${OPTARG}"
      BUILDENVIRONMENT="production"
      BUILDSINGLEBRANCH="false"
      ;;
  esac
done

# Create the require "content" folder
mkdir -p content

# Process the source files
source scripts/processsourcefiles.sh

# BUILD MARKDOWN
# Start HUGO build
hugo server --baseURL "" --environment "$BUILDENVIRONMENT"
