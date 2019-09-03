#!/bin/bash

#########################################################################
# THIS FILE IS USED BY THE NETLIFY SERVER TO RUN AND PUBLISH DOC BUILDS #
#########################################################################

# By default, builds all docs releases from the knative/docs repo.
# Will also extract PR details from webhooks and then build and publish
# content based on the Fork and Branch of the corresponding PR.

# Create a Netlify build webhook and then add it to your GitHub repo fork
# for continuous builds and PR previews.
# (https://www.netlify.com/docs/webhooks/)

# Requirement: You fork must include all releases and maintain the same
# branch names and structure as the knative/docs repo. Otherwise, set up
# your build using the flag: BUILDALLRELEASES="FALSE"

# See all options below for configuring this file to work both your own
# knative/website and knative/docs forks and your own personal Netlify
# account (to set up your own doc preview builds).

# Quit on error
set -e

# Get and set default values
source scripts/docs-version-settings.sh

BUILDALLRELEASES="true"
BRANCH="$DEFAULTBRANCH"
FORK="$DEFAULTFORK"
LOCALBUILD="false"

# Manually specify your fork and branch for all builds.
#
# OPTIONAL: Manually configure your knative/website fork to build from your
#           knative/docs fork by default.
#           (For example, if you have a personal Netlify account and want
#            to easily click the "Deploy" button from the Netlify UI.)
#
#           Example:
#           On the Netlify > Settings > Build & Deploy > Continuous Deployment
#           of your personal account, you can manually set the build command
#           and add include the '-f' and '-b' flags:
#
#           Build command: [./scripts/build.sh -f repofork -b branchname]
#
while getopts f:b:a: arg; do
  echo '------ BUILDING DOCS FROM: ------'
  case $arg in
    f)
      echo "${OPTARG}" 'FORK'
      # Set specified knative/docs repo fork
      FORK="${OPTARG}"
      ;;
    b)
      echo "${OPTARG}" 'BRANCH'
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

# If a webhook triggered the build, get repo fork and branch name
if [[ $INCOMING_HOOK_BODY || $INCOMING_HOOK_TITLE || $INCOMING_HOOK_URL ]]
then
  echo '------ BUILD REQUEST FROM KNATIVE/DOCS WEBHOOK ------'
  echo 'Webhook Title:' "$INCOMING_HOOK_TITLE"
  echo 'Webhook URL:' "$INCOMING_HOOK_URL"
  echo 'Webhook Body:' "$INCOMING_HOOK_BODY"

  # If webhook is from a "PULL REQUEST" event
  if echo "$INCOMING_HOOK_BODY" | grep -q -m 1 '\"pull_request\"'
  then
    # Get PR number
    PULL_REQUEST=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"number\"\:.*\,\"pull_request\"' | sed -e 's/\"number\"\://;s/\,\"pull_request\"//' || true)
    # Retrieve the fork and branch from PR webhook
    FORK_BRANCH=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"label\"\:\".*\"\,\"ref\"' | sed -e 's/\"label\"\:\"knative\:.*//;s/\"label\"\:\"//;s/\"\,\"ref\".*//' || true)
    # Extract just the fork name
    FORK=$(echo "$FORK_BRANCH" | sed -e 's/\:.*//')
    # If PR was merged, just run default build and deploy production site (www.knative.dev)
    MERGEDPR=$(echo "$INCOMING_HOOK_BODY" | grep -o '\"merged\"\:true\,' || : )
    if [ "$MERGEDPR" ]
    then
      echo '------ PR' "$PULL_REQUEST" 'MERGED ------'
      echo 'Running production build - publishing new changes'
    else
      # If PR was not merged, extract the branch name (to use for preview build)
      BRANCH=$(echo "$FORK_BRANCH" | sed -e 's/.*\://')
    fi
  else
    # Webhook from "PUSH event"
    # If the event was from someone's fork, then get their branchname
    if [ "$FORK" != "knative" ]
    then
      BRANCH=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 ':"refs\/heads\/.*\"\,\"before\"' | sed -e 's/.*:\"refs\/heads\///;s/\"\,\"before\".*//' || true)
    fi
  fi
else
  echo 'Full production build triggered - Building docs content from HEAD'
fi

echo '------ BUILD DETAILS ------'
echo 'Build type:' "$CONTEXT"
if [ "$FORK" != "knative" ]
then
echo 'Building content from:' "$FORK"
echo 'Using Branch:' "$BRANCH"
fi
echo 'Commit HEAD:' "$HEAD"
echo 'Commit SHA:' "$COMMIT_REF"
# Other Netlify flags that aren't currently useful
#echo 'Repo:' "$REPOSITORY_URL"
# Doesnt seem to like multiple repos and always returns false when not overriden (see above)
echo 'Pull Request:' "$PULL_REQUEST"
#echo 'GitHub ID:' "$REVIEW_ID"

echo '------ WHEN BUILD SUCCESSFULLY COMPLETES ------'
# Only show published site if build triggered by PR merge
if [ "$MERGEDPR" ]
then
echo '------ CONTENT PUBLISHED ------'
echo 'View published content at:' "$URL"
else
echo '------ PREVIEW CHANGES ------'
# Gets overritten and shows only latest build
#echo 'Shared staging URL:' "$DEPLOY_PRIME_URL"
echo 'View staged content (unique to only this build):' "$DEPLOY_URL"
fi

# Process the source files
source scripts/processsourcefiles.sh

# BUILD MARKDOWN
# Start HUGO build
cd themes/docsy && git submodule update -f --init && cd ../.. && hugo

echo '------ BUILD SUCCESSFUL ------'
echo 'VIEW STAGED CONTENT:' "$DEPLOY_URL"
echo '------------------------------'
