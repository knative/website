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
  # Get versions of released docs from their branches in "$FORK"/docs
  echo 'The /docs/ section is built from the' "$BRANCH" 'branch of' "$FORK"
  # Latest version is defined in website/scripts/docs-version-settings.sh
  # If this is a PR build, then build that content as the latest release (assume PR preview builds are always from "latest")
  git clone --quiet -b "$BRANCH" https://github.com/"$FORK"/docs.git temp/release/latest
  # Only copy and keep the "docs" folder from all branched releases:
  mv temp/release/latest/docs content/en/docs
  echo 'Getting the archived docs releases from branches in:' "$FORK"'/docs'
    ###############################################################
    # Template for next release:
    #git clone -b "release-[VERSION#]" https://github.com/"$FORK"/docs.git temp/release/[VERSION#]
    #mv temp/release/[VERSION#]/docs content/en/[VERSION#]-docs
    ###############################################################
  git clone --quiet -b "release-0.15" https://github.com/"$FORK"/docs.git temp/release/v0.15
  mv temp/release/v0.15/docs content/en/v0.15-docs
  git clone --quiet -b "release-0.14" https://github.com/"$FORK"/docs.git temp/release/v0.14
  mv temp/release/v0.14/docs content/en/v0.14-docs
  git clone --quiet -b "release-0.13" https://github.com/"$FORK"/docs.git temp/release/v0.13
  mv temp/release/v0.13/docs content/en/v0.13-docs

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
# Therefore, the following changes need to be made to all docs files prior to Hugo site build.
# Convert GitHub enabled source, into HUGO supported content:
#  - For all Markdown files under the /content/ directory:
#    - Skip all:
#      - Markdown link with fully qualified HTTP(s) URL is 'external'
#      - GitHub file (.git* files)
#      - non-docs directories
#    - Ignore Hugo site related files (avoid "readfile" shortcodes):
#      - _index.md files (Hugo 'section' files)
#      - API shell files (serving-api.md, eventing-contrib-api.md, eventing-api.md)
#    - For all remaining Markdown files:
#      - Remove all '.md' file extensions from within Markdown links "[]()"
#      - For SEO convert README to index:
#       - Replace all in-page URLS from "README.md" to "index.html"
#       - Rename all files from "README.md" to "index.md"
#      - Adjust relative links by adding additional depth:
#       - Exclude all README.md & _index.md files
#       - Convert './' to '../'
#       - Convert '../' to '../../'
echo 'Converting all links in GitHub source files to Hugo supported relative links...'
# Convert relative links to support Hugo
find . -type f -path '*/content/*.md' ! -name '*_index.md' ! -name '*README.md' \
    ! -name '*serving-api.md' ! -name '*eventing-contrib-api.md' ! -name '*eventing-api.md' \
    ! -name '*build-api.md' ! -name '*.git*' ! -path '*/.github/*' ! -path '*/hack/*' \
    ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' \
    -exec sed -i '/](/ { s#(\.\.\/#(../../#g; s#(\.\/#(../#g; }' {} +
# Convert all relative links from README.md to index.html
find . -type f -path '*/content/*.md' ! -name '_index.md' \
    -exec sed -i '/](/ { /http/ !{s#README\.md#index.html#g;s#\.md##g} }' {} +

###############################################
# Process file names (HIDE README.md FROM URLS)
# For SEO, dont use "README" in the URL
# (convert them to index.md OR use a "readfile" shortcode to nest them within a _index.md section file)
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
    -execdir bash -c 'if [ -e _index.md -o -e index.md ]; then echo "_index.md exists - skipping ${PWD#*/}"; else mv "$1" "${1/\README/\index}"; fi' -- {} \;

# GET HANDCRAFTED SITE LANDING PAGE
echo 'Copying the override files into the /content/ folder'
cp -rfv content-override/* content/
