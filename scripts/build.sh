#!/bin/bash

# Quit on error
set -e

# Set default branch
DEFAULTBRANCH=release-0.3
BRANCH="$DEFAULTBRANCH"

# Get and use specified branch name otherwise, use default (latest release)
# Check if branch was manually specified (ie. force a branch to run specific test builds -> not to knative.dev)
# (Example [in netlify.toml]: command = "./scripts/build.sh -b specifiedbranchname")
while getopts b: branch
do
echo '------ MANUAL BUILD REQUESTED ------'
# Set specified branch
BRANCH=${OPTARG}
done

# If a webhook requested the build, find and use that branch name
# Check for webhook payload 
if [[ $INCOMING_HOOK_BODY || $INCOMING_HOOK_TITLE || $INCOMING_HOOK_URL ]]
then
# First look for "merged" content
MERGEDPR=$(echo $INCOMING_HOOK_BODY | grep -o '\"merged\"\:true\,' || true)
# If a merged PR if found, then deploy to knative.dev
if [[ $MERGEDPR ]]
then
echo '------ PR' "$PULL_REQUEST" 'MERGED ------'
echo 'Running production build...'
else
echo '------ BUILD REQUEST FROM WEBHOOK ------'
echo 'Webhook Title:' "$INCOMING_HOOK_TITLE"
echo 'Webhook URL:' "$INCOMING_HOOK_URL"
# Verbose so hide the body unless you need to troubleshoot
#echo 'Webhook Body:' "$INCOMING_HOOK_BODY"
# Getting branch from webhook
echo 'Parsing Webhook request for branch name'
# Check if webhook request came from an open PR
PULLREQUEST=$(echo $INCOMING_HOOK_BODY | grep -o -m 1 '\"pull_request\"' || true)
if [[ $PULLREQUEST ]]
then
# Webhook from an in-progress PR
GETPRBRANCH=$(echo $INCOMING_HOOK_BODY | grep -o -m 1 '\"head\"\:{\"label\":.*\"ref\"\:\".*\"\,\"sha' || true)
BRANCH1=$(echo $GETPRBRANCH | sed -e 's/\"\,\"sha\"\:.*//;s/.*\"ref\"\:\"//')
else
# GitHub "Push"
GETRELEASEBRANCH=$(echo $INCOMING_HOOK_BODY | grep -o ':"refs\/heads\/.*\"\,\"before\":' || true)
BRANCH=$(echo $GETRELEASEBRANCH | sed -e 's/:\"refs\/heads\///;s/\"\,\"before\"://')
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
# Not useful
#echo 'Repo:' "$REPOSITORY_URL"
# Doesnt seem to like multiple repos and always returns false
#echo 'Pull Request:' "$PULL_REQUEST"
#echo 'GitHub ID:' "$REVIEW_ID"

echo '------ PROCESSING SOURCE FILES ------'
# Connect the separate site source and docs source repos
# Prevent clone error (git clone fails if directory exists)
# This forces a complete build of the site for each request
echo 'Deleting past clone for new copy...'
rm -rf content
# Get latest source from https://github.com/knative/docs
echo 'Cloning docs source from the' "$BRANCH" 'branch of https://github.com/knative/docs...'
git clone -b "$BRANCH" https://github.com/knative/docs.git content/en

# Convert GitHub enabled source, into HUGO supported content:
#  - Remove all .md file extensions 
#  - Ensure any paths to "README.md" are truncated to containing folder
#  - ignore all _index.md files (req. Hugo 'section' files)
#  - ignore .git* files
#  - ignore non-docs source directories
#  - ignore temporary API shell files (until those API source builds are modified to include frontmatter)
echo 'Converting links in GitHub source for Hugo build...'
find . -type f -path '*/content/*.md' ! -name '*_index.md' ! -name '*serving-api.md' ! -name '*eventing-sources-api.md' ! -name '*eventing-api.md' ! -name '*build-api.md' ! -name '*.git*' ! -path '*/.github/*' ! -path '*/hack/*' ! -path '*/test/*' ! -path '*/vendor/*' -print | xargs grep -Ei ".md)" | grep -Eiv "\(http[s]" | sed 's#/README.md)#/)#g;s#\.md)#)#g'

# Start HUGO build
hugo

echo '------ VIEW BUILD OUTPUT ------'
# Only show published site if build triggered by PR merge
if [[ $MERGEDPR ]]
then
echo 'Merged content is published at:' "$URL"
else
echo 'Shared staging URL:' "$DEPLOY_PRIME_URL"
echo 'Unique build URL:' "$DEPLOY_URL"
fi
