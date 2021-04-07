# knative-docs-docker

```bash
git clone git@github.com:knative/website.git
```

```bash
cd website/docker
```

```bash
docker build -t {USER/knative-docs} .
```

There are custom scripts that avoid deletion of this folder in processsourcefiles. If using the default version of the script (not in the Dockerfile image build) then it will delete the directory. **Test this out using a test directory you have cloned and change GOPATH to the test directory. (/home/user/testing/docs/docs)**

Just Docs
```bash
docker run --name=knative-docs -d -v $GOPATH/src/github.com/knative.dev/docs/docs:/website/content/en/docs -p 9001:1313 USER/knative-docs:latest
```

Docs and Blog
```bash
docker run --name=knative-docs -d -v $GOPATH/src/github.com/knative.dev/docs/docs:/website/content/en/docs -v $GOPATH/src/github.com/knative.dev/docs/blog:/website/content/en/blog -p 9001:1313 USER/knative-docs:latest
```

This will run the service on port 9001, but you can pick any port you want. The container is listening on 1313.


Diffs on script files (edited so that mounted volumes aren't deleted or copied over)

```
$ diff localbuild.sh ../knative.dev/website/scripts/localbuild.sh 
153,157c153,157
<       SERVER="server "
<      # if [ "${OPTARG}" = "reload" ]; then
<      #   echo 'with live reload'
<      #   LIVERELOAD=" --disableFastRender --renderToDisk"
<      # fi
---
>       SERVER="server $LIVERELOAD"
>       if [ "${OPTARG}" = "reload" ]; then
>         echo 'with live reload'
>         LIVERELOAD=" --disableFastRender --renderToDisk"
>       fi
170c170
< exec hugo $SERVER --disableFastRender --baseURL "" --environment "$BUILDENVIRONMENT" --bind=0.0.0.0 --gc
---
> hugo $SERVER --baseURL "" --environment "$BUILDENVIRONMENT" --gc
178d177
< 
```

```
$ diff processsourcefiles.sh ../../knative.dev/website/scripts/processsourcefiles.sh 
11c11
< # rm -rf content/en
---
> rm -rf content/en
30c30
<   # mv content/en/docs content/en/development
---
>   mv content/en/docs content/en/development
70c70
<   #cp -r ../docs content/en/
---
>   cp -r ../docs content/en/
187d186
< 
```
