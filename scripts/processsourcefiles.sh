#######################################################################################
# THIS FILE IS USED BY BOTH THE 'build.sh' and the 'localbuild.sh' DOCS BUILD SCRIPTS #
#######################################################################################

echo '------ PROCESSING SOURCE FILES ------'
# Pull in content from the separate community source and docs source repos
# (make it look like they live in the content folder of knative/website )
# Use a temp directory and move files around to prevent git clone error (fails if directory exists)
# Note: This forces a complete build of all versions of all files in the site

if "$LOCALBUILD"
then
echo '------ RUNNING A LOCAL BUILD ------'
fi

# Clean slate: Make sure that nothing from a past build exists in the /content/ or /temp/ folders
rm -rf content/en
rm -rf temp
echo 'Cloning Knative documentation from their source repositories.'

if "$BUILDALLRELEASES"
then
  echo '------ BUILDING ALL DOC RELEASES FROM' "$FORK" '------'
  # Build Knative docs from:
  # - https://github.com/"$FORK"/docs
  # - https://github.com/knative/community
  echo '------ Cloning Pre-release docs (master) ------'
  # MASTER
  echo 'Getting blog posts and community owned samples from knative/docs master branch'
  git clone -b master https://github.com/"$FORK"/docs.git content/en
  echo 'Getting pre-release development docs from master branch'
  # Move "pre-release" docs content into the 'development' folder:
  mv content/en/docs content/en/development
  # DOCS BRANCHES
  echo '------ Cloning all docs releases ------'
  # Get versions of released docs from their branches in "$FORK"/docs
  echo 'Getting the latest release from the' "$BRANCH" 'branch of' "$FORK"
  git clone -b "$BRANCH" https://github.com/"$FORK"/docs.git temp/release/latest

  ###############################################################
  # Template for next release:
  #git clone -b "release-[VERSION#]" https://github.com/"$FORK"/docs.git temp/release/[VERSION#]
  #mv temp/release/[VERSION#]/docs content/en/[VERSION#]-docs
  ###############################################################

  # Only copy and keep the "docs" folder from all branched releases:
  mv temp/release/latest/docs content/en/docs
  echo 'Getting the archived docs releases'
  git clone -b "release-0.6" https://github.com/"$FORK"/docs.git temp/release/v0.6
  mv temp/release/v0.6/docs content/en/v0.6-docs
  git clone -b "release-0.5" https://github.com/"$FORK"/docs.git temp/release/v0.5
  mv temp/release/v0.5/docs content/en/v0.5-docs
  git clone -b "release-0.4" https://github.com/"$FORK"/docs.git temp/release/v0.4
  mv temp/release/v0.4/docs content/en/v0.4-docs
  git clone -b "release-0.3" https://github.com/"$FORK"/docs.git temp/release/v0.3
  mv temp/release/v0.3/docs content/en/v0.3-docs
  echo 'Moving cloned files into their v#.#-docs website folders'
else
  echo '------ BUILDING ONLY FROM YOUR LOCAL KNATIVE/DOCS CLONE ------'
  pwd
  cp -r ../docs content/en/
fi

echo '------ Cloning contributor docs ------'
# COMMUNITY
echo 'Getting Knative contributor guidelines from the master branch of knative/community'
git clone -b master https://github.com/knative/community.git temp/community
# Move files into existing "contributing" folder
mv temp/community/* content/en/contributing

# CLEANUP
  # Delete temporary directory
  # (clear out unused files, including archived-copies/past-versions of blog posts and contributor samples)
  echo 'Cleaning up temp directory'
  rm -rf temp

# MAKE RELATIVE LINKS WORK
# We want users to be able view and use the source files in GitHub as well as on the site.
# Therefore, the following changes need to be made to all docs files prior to Hugo site build.
# Convert GitHub enabled source, into HUGO supported content:
#  - For all Markdown files under the /content/ directory:
#    - Skip any Markdown link with fully qualified HTTP(s) URL is 'external'
#    - Ignore Hugo site related files (avoid "readfile" shortcodes):
#     - _index.md files (Hugo 'section' files)
#     - API shell files (until those API source builds are modified to include frontmatter)
#    - Remove all '.md' file extensions from Markdown links
#    - For SEO convert README to index:
#      - Replace all in-page URLS from "README.md" to "index.html"
#      - Rename all files from "README.md" to "index.md"
#  - For NON-(README.md & _index.md) files:
#    - Adjust relative links by adding additional depth:
#      - Convert './' to '../'
#      - Convert '../' to '../../'
#  - Skip GitHub files:
#    - .git* files
#    - non-docs directories
echo 'Converting all links in GitHub source files to Hugo supported relative links...'
find . -type f -path '*/content/*.md' ! -name '*_index.md' ! -name '*README.md' \
    ! -name '*serving-api.md' ! -name '*eventing-contrib-api.md' ! -name '*eventing-api.md' \
    ! -name '*build-api.md' ! -name '*.git*' ! -path '*/.github/*' ! -path '*/hack/*' \
    ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' \
    -exec sed -i '/](/ { s#(\.\.\/#(../../#g; s#(\.\/#(../#g; /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +
find . -type f -path '*/content/*/*/README.md' ! -name '_index.md' \
    -exec sed -i '/](/ { /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +

# Releases v0.6 and earlier doc releases:
#use the "readfile" shortcodes to hide all the README.md files
# (by nesting them within the _index.md files)
echo 'Converting all README.md to index.md for "pre-release" and 0.7 or later doc releases'
# v0.7 or later doc releases:
# Rename "README.md" files to "index.md" and avoid unnecessary lower-level _index.md files
# (to prevent nested shortcodes that can result in double markdown processing)
# Skip the following README.md files (do not convert them to index.md)
# either because that README.md is for GitHub only, or to prevent conflicts
# with the require _index.md file (Hugo's site section definition file):
#  - all README.md files that with corresponding _index.md files
#  - content/en/contributing/README.md
#  - content/en/reference/README.md
find . -type f -path '*/content/*/*/*' -name 'README.md' \
     ! -path '*/contributing/*' ! -path '*/v0.6-docs/*' ! -path '*/v0.5-docs/*' \
     ! -path '*/v0.4-docs/*' ! -path '*/v0.3-docs/*' ! -path '*/.github/*' ! -path '*/hack/*' \
     ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' \
    -execdir bash -c 'if [ -e _index.md ]; then echo "skip $1"; else mv "$1" "${1/\README/\index}"; fi' -- {} \;


# GET HANDCRAFTED SITE LANDING PAGE
if "$LOCALBUILD"
then
  echo 'Note: Skipping the site override files for local builds (including the main index page for knative.dev)'
else
  echo 'Copying the override files into the /content/ folder'
  cp -rfv content-override/* content/
fi
