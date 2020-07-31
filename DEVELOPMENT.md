# Development instructions

## Setup

1. Clone this repo (or your fork) using `--recurse-submodules`, like so:

   ```shell
   git clone --recurse-submodules https://github.com/knative/website.git
   ```

   If you accidentally cloned this repo without `--recurse-submodules`, you'll
   need to do the following inside the repo:

   ```shell
   git submodule init
   git submodule update
   cd themes/docsy
   git submodule init
   git submodule update
   ```

   (Docsy uses two submodules, but those don't use further submodules.)

1. Clone the docs repo next to (_not inside_) the website repo. This allows you
   to test docs changes alongside the website:

   ```shell
   git clone https://github.com/knative/docs.git
   ```

   You may also want to clone the community repo:

   ```shell
   git clone https://github.com/knative/community.git
   ```

1. (Optional) If you want to change the CSS, install
   [PostCSS](https://www.docsy.dev/docs/getting-started/#install-postcss)

## Run locally

You should be able to run `./scripts/localbuild.sh` to generate a copy of the
docs in the `public/` folder. Note that the build will replace relative
`.../index.html` links with `.../`, so when browsing the local copy, you may
need to click on `index.html` files to get where you need to go.

If you want the old behavior of starting a local webserver, you can run
`./scripts/localbuild.sh -s`, but see the notes below on the tradeoff:

There are two benefits to preferring to build statically:

- It's easier to read or use tools on the output files, rather than needing to
  fetch the HTML from the server. This is particularly useful when refactoring
  the website or doing other complicated rendering.

- It avoids an issue (see below) on Macs, where the default open FD limit is too
  low for the number of `inotify` calls that hugo wants to keep open.

Additionally, since the script _copies_ your `docs` repo, the live-reload is
substantilly less useful than re-running the build and using a fresh copy.

## On a Mac

If you want to develop on a Mac, you'll find two obstacles:

### Sed

The scripts assume GNU `sed`. You can install this with
[Homebrew](https://brew.sh/):

```shell
brew install gnu-sed
# You need to put it in your PATH before the built-in Mac sed
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

### File Descriptors in "server mode"

By default, MacOS permits a very small number of open FDs. This will manifest
as:

```
ERROR 2020/04/14 12:37:16 Error: listen tcp 127.0.0.1:1313: socket: too many open files
```

You can fix this with the following (may be needed for each new shell):

```shell
sudo launchctl limit maxfiles 65535 200000
# Probably only need around 4k FDs, but 64k is defensive...
ulimit -n 65535
sudo sysctl -w kern.maxfiles=100000
sudo sysctl -w kern.maxfilesperproc=65535
```
