#!/bin/bash

#########################################################################
# THIS FILE IS USED BY THE NETLIFY SERVER TO RUN AND PUBLISH DOC BUILDS #
#########################################################################

# See options below for configuring this file in your own repo fork for use
# with your own personal Netlify account (to build your own site preview).

# Quit on error
set -e

source scripts/docs-version-settings.sh

BUILDALLRELEASES="true"
BRANCH="$DEFAULTBRANCH"
FORK="$DEFAULTFORK"

# Get and use specified fork and branch name.
# By default, build all releases from knative/docs.
#
# OPTIONAL: Configure your knative/website fork to build from your knative/docs
#           fork (for example, use a personal Netlify account from previews).
#           Example:
#           In the netlify.toml config file of your knative/website fork, you
#           can add the '-f' and '-b' flags and values to the build command:
#
#            [build]
#             publish = "public"
#             command = "./scripts/build.sh -f repofork -b branchname"
#
while getopts f:b:a: arg; do
  echo '------ BUILDING DOCS FROM: ------'
  case $arg in
    f)
      echo '"${OPTARG}" FORK'
      # Set specified knative/docs repo fork
      FORK="${OPTARG}"
      ;;
    b)
      echo '"${OPTARG}" BRANCH'
      # Set specified branch
      BRANCH="${OPTARG}"
      ;;
    a)
      echo 'BUILDING ALL RELEASES'
      # True by default. If set to "false" , the build does not clone nor build
      # the docs releases from other branches.
      # REQUIRED: To build all docs version when $FORK is specified, all
      # knative/docs branches must also exist in the target $FORK, and
      # the names of each branch must match the branches of the knative/docs
      # repo ('release-0.X'). For example: 'release-0.7', 'release-0.6', etc...
      BUILDALLRELEASES="${OPTARG}"
      ;;
  esac
done

# If a webhook requested the build, find and use that repo fork and branch name
# Check for webhook payload
if [[ $INCOMING_HOOK_BODY || $INCOMING_HOOK_TITLE || $INCOMING_HOOK_URL ]]
then
# First look for "merged" content
MERGEDPR=$(echo "$INCOMING_HOOK_BODY" | grep -o '\"merged\"\:true\,' || true)
# If a merged PR if found, then deploy production site (www.knative.dev)
if [[ $MERGEDPR ]]
then
echo '------ PR' "$PULL_REQUEST" 'MERGED ------'
echo 'Running production build...'
else
echo '------ BUILD REQUEST FROM WEBHOOK ------'
echo 'Webhook Title:' "$INCOMING_HOOK_TITLE"
echo 'Webhook URL:' "$INCOMING_HOOK_URL"
echo 'Webhook Body:' "$INCOMING_HOOK_BODY"
# Getting branch from webhook
echo 'Parsing Webhook request for branch name'
# Check if webhook request came from an PR
PULLREQUEST=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"pull_request\"' || true)
if [[ $PULLREQUEST ]]
then
# Webhook from a PR
GETPRBRANCH=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"head\"\:{\"label\":.*\"ref\"\:\".*\"\,\"sha' || true)
BRANCH1=$(echo "$GETPRBRANCH" | sed -e 's/\"\,\"sha\"\:.*//;s/.*\"ref\"\:\"//')
else
# Webhook from a 'git push'
GETRELEASEBRANCH=$(echo "$INCOMING_HOOK_BODY" | grep -o ':"refs\/heads\/.*\"\,\"before\":' || true)
BRANCH=$(echo "$GETRELEASEBRANCH" | sed -e 's/:\"refs\/heads\///;s/\"\,\"before\"://')
fi
fi
else
echo 'Running default branch build'
fi

echo '------ BUILD DETAILS ------'
echo 'Build type:' "$CONTEXT"
echo 'Building docs from branch:' "$BRANCH"
echo 'Commit HEAD:' "$HEAD"
echo 'Commit SHA:' "$COMMIT_REF"
# Other Netlify flags that aren't currently useful
#echo 'Repo:' "$REPOSITORY_URL"
# Doesnt seem to like multiple repos and always returns false
#echo 'Pull Request:' "$PULL_REQUEST"
#echo 'GitHub ID:' "$REVIEW_ID"

source scripts/processsourcefiles.sh

# BUILD MARKDOWN
# Start HUGO build
cd themes/docsy && git submodule update -f --init && cd ../.. && hugo

# Only show published site if build triggered by PR merge
if [[ $MERGEDPR ]]
then
echo '------ CONTENT PUBLISHED ------'
echo 'Merged content will be live at:' "$URL"
else
echo '------ PREVIEW CHANGES ------'
echo 'Shared staging URL:' "$DEPLOY_PRIME_URL"
echo 'URL unique to this build:' "$DEPLOY_URL"
fi
