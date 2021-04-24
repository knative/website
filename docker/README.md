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

If you want to run an already built image you can specify mpetason/knative-docs:latest instead of building locally.

Just Docs
```bash
docker run --name=knative-docs -d -v $GOPATH/src/github.com/knative.dev/docs/docs:/website/content/en/docs -p 9001:1313 mpetason/knative-docs:latest
```

Docs and Blog
```bash
docker run --name=knative-docs -d -v $GOPATH/src/github.com/knative.dev/docs/docs:/website/content/en/docs -v $GOPATH/src/github.com/knative.dev/docs/blog:/website/content/en/blog -p 9001:1313 mpetason/knative-docs:latest
```