#!/bin/bash

##############################################
# THE DEFAULT DOCS REPO AND VERSION SETTINGS #
##############################################

# This should be set to the latest docs release/branch
DEFAULTBRANCH="release-0.16"

# Latest release version number
LATESTVERSION="16"
# Total number of past versions to publish
NUMOFVERSIONS="3"
OLDESTVERSION=$((LATESTVERSION-NUMOFVERSIONS))

# An optional value that you can locally override for local builds/testing
DEFAULTFORK="knative"
