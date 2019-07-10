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

# Make sure that nothing exists in the /content/ folder from the last build
rm -rf content/en

if "$BUILDALLRELEASES"
then
  echo '------ BUILDING ALL RELEASES ------'
  # Get latest source from:
  # - https://github.com/"$FORK"/docs
  # - https://github.com/"$FORK"/community
  echo 'Cloning Knative documentation from their source repositories.'
  # MASTER
  echo 'Getting blog posts and community owned samples from knative/docs master branch'
  git clone -b master https://github.com/"$FORK"/docs.git content/en
  echo 'Getting pre-release development docs from master branch'
  # Move "pre-release" docs content into the 'development' folder:
  mv content/en/docs content/en/development
  # COMMUNITY
  echo 'Getting Knative contributor guidelines from knative/community'
  git clone -b master https://github.com/knative/community.git temp/communtiy
  # Move files into existing "contributing" folder (includes site's '_index.md' section definition)
  echo 'Move content into contributing folder'
  mv temp/communtiy/* content/en/contributing
  # DOCS BRANCHES
  # Get versions of released docs from their branches in "$FORK"/docs
  echo 'Begin fetching all version of the docs...'
  echo 'Getting the latest release from the ' "$BRANCH" 'of ' "$FORK"
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
  # CLEANUP
  # Delete temporary directory
  # (clear out unused files, including archived-copies/past-versions of blog posts and contributor samples)
  echo 'Cleaning up temp directory'
  rm -rf temp
else
  echo 'BUILDING ONLY FROM YOUR LOCAL KNATIVE/DOCS CLONE'
  pwd
  cp -r ../docs content/en/
fi

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
find . -type f -path '*/content/*.md' ! -name '*_index.md' ! -name '*README.md' ! -name '*serving-api.md' ! -name '*eventing-contrib-api.md' ! -name '*eventing-api.md' ! -name '*build-api.md' ! -name '*.git*' ! -path '*/.github/*' ! -path '*/hack/*' ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' -exec sed -i '/](/ { s#(\.\.\/#(../../#g; s#(\.\/#(../#g; /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +
find . -type f -path '*/content/*/*/README.md' -exec sed -i '/](/ { /http/ !s#README\.md#index.html#g; /http/ !s#\.md##g }' {} +

# Releases v0.6 and earlier use the "readfile" shortcodes to hide all the README.md files
# (by nesting them within the _index.md files)
echo 'Converting all README.md to index.md for "pre-release" and later releases'
# The newer doc releases have changed to renaming all "README.md" files to "index.md",
# and exclude the lower-level _index.md files (nor the related nested "readfile" shortcodes)
# TEST ON MASTER BRANCH ONLY (cherry-pick to 0.7 after testing)
find . -type f -path '*/content/*/*/README.md'  ! -path '*/v0.7-docs/*' ! -path '*/v0.6-docs/*' ! -path '*/v0.5-docs/*' ! -path '*/v0.4-docs/*' ! -path '*/v0.3-docs/*' ! -path '*/.github/*' ! -path '*/hack/*' ! -path '*/node_modules/*' ! -path '*/test/*' ! -path '*/themes/*' ! -path '*/vendor/*' -exec bash -c 'mv "$1" "${1/\README/\index}"' -- {} \;

# GET HANDCRAFTED SITE LANDING PAGE
if "$LOCALBUILD"
then
  echo 'Skip/dont the site override files (including the main index page for knative.dev)'
else
  echo 'Copy the override files into the /content/ folder'
  cp -rfv content-override/* content/
fi
