#!/bin/bash

# Quit on error
set -e

# Set default branch (latest docs release)
DEFAULTBRANCH="release-0.3"
BRANCH="$DEFAULTBRANCH"

# Get and use specified branch name otherwise, use default (latest release)
# Check if branch was manually specified (ie. force a branch to run specific test builds -> not to knative.dev)
# (Example [in netlify.toml]: command = "./scripts/build.sh -b specifiedbranchname")
while getopts b: branch
do
echo '------ MANUAL BUILD REQUESTED ------'
# Set specified branch
BRANCH="${OPTARG}"
done

# If a webhook requested the build, find and use that branch name
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
# Check if webhook request came from an open PR
PULLREQUEST=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"pull_request\"' || true)
if [[ $PULLREQUEST ]]
then
# Webhook from an in-progress PR
GETPRBRANCH=$(echo "$INCOMING_HOOK_BODY" | grep -o -m 1 '\"head\"\:{\"label\":.*\"ref\"\:\".*\"\,\"sha' || true)
BRANCH1=$(echo "$GETPRBRANCH" | sed -e 's/\"\,\"sha\"\:.*//;s/.*\"ref\"\:\"//')
else
# GitHub "Push"
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
# Not useful
#echo 'Repo:' "$REPOSITORY_URL"
# Doesnt seem to like multiple repos and always returns false
#echo 'Pull Request:' "$PULL_REQUEST"
#echo 'GitHub ID:' "$REVIEW_ID"

echo '------ PROCESSING SOURCE FILES ------'
# Connect the separate site source and docs source repos
# Prevent clone error (git clone fails if directory exists)
# This forces a complete build of the site for each request
echo 'Deleting content dir...'
rm -rf content/en

# Get latest source from https://github.com/knative/docs
echo 'Cloning docs source from the' "$BRANCH" 'branch of https://github.com/knative/docs...'
git clone -b "$BRANCH" https://github.com/knative/docs.git content/en

# Temporary copies of v0.3 to validate versioning on Production site
mv content/en/docs content/en/development
git clone -b "$BRANCH" https://github.com/knative/docs.git temp/release/latest
mv temp/release/latest/docs content/en/docs
git clone -b "$BRANCH" https://github.com/knative/docs.git temp/release/v0.3
mv temp/release/v0.3/docs content/en/v0.3-docs

# HOLD until master branch is updated for website
#echo 'Getting community, blog, and contributor content from master branch'
#git clone https://github.com/knative/docs.git content/en
#echo 'Getting pre-release development docs from master branch'
# Docs in 'master' branch are "pre-release" only:
#mv content/en/docs content/en/development
#echo 'Getting the latest docs release from' "$BRANCH" 'branch'
#git clone -b "$BRANCH" https://github.com/knative/docs.git temp/release/latest
# Only copy and keep the "docs" folder from all branched releases:
#mv temp/release/latest/docs content/en/docs
#echo 'Getting the archived docs releases
#git clone -b "release-0.3" https://github.com/knative/docs.git temp/release/v0.3
#mv temp/release/v0.3/docs content/en/v0.3-docs

# Template for next release:
#git clone -b "release-[VERSION#]" https://github.com/knative/docs.git temp/release/[VERSION#]
#mv temp/release/[VERSION#]/docs content/en/[VERSION#]-docs

# Delete temp directory (old copies of shared content: blog, contributing, community)
rm -rf temp

# Convert GitHub enabled source, into HUGO supported content:
#  - For all 'content/*.md' files:
#    - Skip/assume any Markdown link with fully qualified HTTP(s) URL is 'external'
#    - Otherwise, remove all '.md' file extensions from Markdown links
#    - Replace all "README.md" with "index.html"
#  - For files NOT included using the "readfile" shortcode:
#     (exclude all README.md files from relative link adjustment)
#    - Adjust relative links by adding additional depth:
#      - Convert './' to '../'
#      - Convert '../' to '../../'
#  - Ignore Hugo site related files:
#     - _index.md files (req. Hugo 'section' files)
#     - API shell files (until those API source builds are modified to include frontmatter)
#  - Skip GitHub files:
#    - .git* files
#    - non-docs directories
echo 'Converting all GitHub links in source for Hugo build...'
find . -type f -path '*/content/*.md' ! -name '*_index.md' ! -name '*README.md' ! -name '*serving-api.md' ! -name '*eventing-sources-api.md' ! -name '*eventing-api.md' ! -name '*build-api.md' ! -name '*.git*' ! -path '*/.github/*' ! -path '*/hack/*' ! -path '*/test/*' ! -path '*/vendor/*' -exec sed -i '/](/ { /\!\[/ !s#(\.\.\/#(../../#g; /\!\[/ !s#(\.\/#(../#g; /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +
find . -type f -path '*/content/*README.md' -exec sed -i '/](/ { /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +

# Start HUGO build
hugo

echo '------ VIEW BUILD OUTPUT ------'
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
