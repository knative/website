#######################################################################################
# THIS FILE IS USED BY THE 'processsourcefiles.sh' SCRIPT TO CONVERT URLS TO RELATIVE #
#######################################################################################

echo '------ CONVERT FULLY QUALIFIED REPO URLS TO RELATIVE ------'
# Convert fully-qualified URLs that are used in the Knative GitHub repos source files
# to link from repo to repo, into relative URLs for publishing to the knative.dev site.
#
# To ensure that content is usable when viewed within the Knative GitHub repos,
# links that span across repos use fully-qualified URLs. However, for the
# content published on knative.dev, we need to convert those fully-qualified URLs
# to Hugo relative URLs* to avoid the knative.dev site default behavior of opening
# fully-qualified URLs in new browser window tabs.
# * Hugo's "relative" URLs are root-of-domain based (relative to the knative.dev root):
#   https://gohugo.io/content-management/urls/#relative-urls
#
# To convert URLS to root-based relative URLS, remove the following:
# - Remove repo domains:
#   - "https://github.com/knative/community/"
#   - "https://github.com/knative/docs/"
# - Remove GitHub "tree|blob" paths (ie "/tree/master/" or "/blob/master/")
#   Note: Assume all links point to the `master` branch.
# - Exclude issues or pulls URLs:
#   - https://github.com/knative/(docs|community)/issues
#   - https://github.com/knative/(docs|community)/pulls

echo 'Converting all fully-qualified Knative URLs to relative URLs...'

# For URLs in the files of the knative/community repo that point to knative/docs:
find . -type f -path '*/community/*.md' \
    -exec sed -i '/](https:\/\/github\.com\/knative\/docs/ { /docs\/issues/ !{ /docs\/pulls/ !{s#(https\:\/\/github\.com\/knative\/docs\/#(/docs/#g}}; s#\/tree\/master\/docs\/#/#g; s#\/blob\/master\/docs\/#/#g; }' {} +

# For URLs in the files of the knative/docs repo that point to knative/community:
find . -type f -path '*/docs/*.md' -path '*/v*\-docs/*.md' \
    -exec sed -i '/](https:\/\/github\.com\/knative\/community/ { /docs\/issues/ !{ /docs\/pulls/ !{s#(https\:\/\/github\.com\/knative\/community\/#(/community/contributing/#g}}; s#\/tree\/master\/#/#g; s#\/blob\/master\/#/#g; }' {} +
