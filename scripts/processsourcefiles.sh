#######################################################################################
# THIS FILE IS USED BY BOTH THE 'build.sh' and the 'localbuild.sh' DOCS BUILD SCRIPTS #
#######################################################################################

echo '------ PROCESSING SOURCE FILES ------'
# Default to a local build. Otherwise, retreives content from the specified source repos.
# All builds copy or clone the content into the "content" folder of knative/webiste before starting the Hugo build.
# A temp directory is used and move files around and prevent git clone errors (fails if directory exists).

# Clean slate: Make sure that nothing from a past build exists in the /content/ or /temp/ folders
rm -rf content/en
rm -rf temp

if [ "$BUILDALLRELEASES" = "true" ]
then
# PRODUCTION BUILD (ALL RELEASES)
# Full build for knative.dev (config/production). Contributors can also use this for personal builds.
  echo '------ BUILDING ALL DOC RELEASES ------'
  # Build Knative docs from:
  # - https://github.com/"$FORK"/docs
  # - https://github.com/knative/community

  # Build all branches (assumes $FORK contains all docs versions)
  echo '------ Cloning Community and Pre-release docs (master) ------'
  # MASTER
  echo 'Getting blog posts and community owned samples from knative/docs master branch'
  git clone --quiet -b master https://github.com/"$FORK"/docs.git content/en
  echo 'Getting pre-release development docs from master branch'
  # Move "pre-release" docs content into the 'development' folder:
  mv content/en/docs content/en/development
  # DOCS BRANCHES
  echo '------ Cloning all docs releases ------'

  # TODO(Evan): Avoid the need for `mv` above and make the below just ap
  # set of clone + symlink commands

  # Get versions of released docs from their branches in "$FORK"/docs
  # Latest version is defined in website/scripts/docs-version-settings.sh
  # If this is a PR build, then build that content as the latest release (assume PR preview builds are always from "latest")
  echo 'Getting the archived docs releases from branches in:' "$FORK"'/docs'
  mkdir -p docs  # -p won't fail if the file exists
  r=$OLDESTVERSION
  while [[ $r -le $LATESTVERSION ]]
  do
    CLONE="docs/release-0.${r}"
    if [[ -e "$CLONE" ]]
    then
      echo "Skipping ${CLONE}, a copy of those archived docs already exists."
      ln -s ../../"$CLONE"/docs content/en/v0."$r"-docs #always recreate symlinks because /content/en always gets wiped out
    else
     echo 'Getting docs from: release-0.'"${r}"
     git clone --quiet -b "release-0.${r}" "https://github.com/${FORK}/docs.git" "$CLONE"
     if [ "$r" = "$LATESTVERSION" ]
     then  
       echo 'The /docs/ section is built from:' "$FORK"/release-0.'"${r}"
       mv "$CLONE"/docs content/en/docs
       rm -rf "$CLONE" #always get the latest release
    else
       # Only use the "docs" folder from all branches/releases
       ln -s ../../"$CLONE"/docs content/en/v0."$r"-docs
     fi
    fi
    (( r = r + 1 ))
  done

elif [ "$BUILDSINGLEBRANCH" = "true" ]
then
# SINGLE REMOTE BRANCH BUILD
# Build only the content from $FORK and $BRANCH
  echo '------ BUILDING CONENT FROM REMOTE ------'
  echo 'The /docs/ section is built from the' "$BRANCH" 'branch of' "$FORK"'/docs'
  git clone --quiet -b "$BRANCH" https://github.com/"$FORK"/docs.git content/en
else
# DEFAULT: LOCAL BUILD
# Assumes that knative/docs and knative/website are cloned to the same directory.
  LOCALBUILD="true"
  echo '------ BUILDING ONLY FROM YOUR LOCAL KNATIVE/DOCS CLONE ------'
  echo 'Copying local clone of knative/docs into the /docs folder under:'
  pwd

  # TODO(Evan): switch this to just be symlinks?

  cp -r ../docs content/en/
  if [ -d "../community" ]; then
    echo 'Also copying the local clone of knative/community into the /community/contributing folder.'
    cp -r ../community/* content/en/community/contributing
  else
    echo 'A local clone of knative/community is not found, skipping that content.'
  fi
fi

if [ "$LOCALBUILD" = "false" ]
then
  echo '------ Cloning contributor docs ------'
  # COMMUNITY
  # TODO / Known issue: Auto PR builds will fail if remote fork excludes knative/community -> https://app.netlify.com/sites/knative/deploys
  echo 'Getting Knative contributor guidelines from the master branch of' "$FORK"'/community'
  git clone --quiet -b master https://github.com/"$FORK"/community.git temp/community
  # Move files into existing "contributing" folder
  mv temp/community/* content/en/community/contributing
fi

# CLEANUP
# Delete temporary directory
# (clear out unused files, including archived-copies/past-versions of blog posts and contributor samples)
echo 'Cleaning up temp directory used during this site build.'
rm -rf temp

###################################################
# Process fully-qualified hard coded URLs that link
# between the knative/docs and knative/community repos
source scripts/convert-repo-ulrs.sh

#########################################################
# Process content in .md files (MAKE RELATIVE LINKS WORK)
# We want users to be able view and use the source files in GitHub as well as on the site.
#
# See layouts/_default/content.html for how this is done.

###############################################
# Process file names (HIDE README.md FROM URLS)
# For SEO, dont use "README" in the URL
# (convert them to index.md OR use a "readfile" shortcode to nest them within a _index.md section file)
# See also https://github.com/gohugoio/hugo/issues/4691 which would resolve this.
#
# Notes about past docs versions:
# v0.6 and earlier doc releases: Use the "readfile" shortcodes to nest all README.md files within the _index.md files.
# v0.7 or later doc releases: Rename "README.md" files to "index.md" to avoid unnecessary lower-level _index.md files
#     (and to prevent deeply nested shortcodes ==> double markdown processing issues).
#     The "readfile" shortcodes are still used but only at the top level.
#
echo 'Converting all standalone README.md files to index.md...'
# Some README.md files should not be converted to index.md, either because that README.md
# is a file that's used only in the GitHub repo, or to prevent Hugo build conflicts
# (index.md and _index.md files in the same directory is not supported).
#
# Do not convert the following README.md files to index.md:
#  - files in doc releases v0.6 and earlier
#  - README.md files in folders that also include _index.md files
#  - content/en/contributing/README.md
#  - content/en/reference/README.md
find . -type f -path '*/content/*/*/*' -name 'README.md' \
     ! -path '*/contributing/*' ! -path '*/v0.6-docs/*' ! -path '*/v0.5-docs/*' \
     ! -path '*/v0.4-docs/*' ! -path '*/v0.3-docs/*' ! -path '*/.github/*' ! -path '*/hack/*' \
     ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' \
    -execdir bash -c 'if [ -e index.md -o -e _index.md ]; then echo "index.md or _index.md exists - skipping ${PWD#*/}"; else mv "$1" "${1/README/index}"; fi' -- {} \;

# GET HANDCRAFTED SITE LANDING PAGE
echo 'Copying the override files into the /content/ folder'
cp -rfv content-override/* content/
