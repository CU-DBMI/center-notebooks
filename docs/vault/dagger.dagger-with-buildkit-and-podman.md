---
id: mebo859qf267oa37xdjloom
title: Dagger with Buildkit and Podman
desc: ''
updated: 1650139991855
created: 1650114759145
---

## Summary

[Dagger](https://docs.dagger.io/) by default will attempt to use Docker installations but does not require Docker to run. Some customization without using Docker is covered on the following page: [Customizing your Buildkit installation](https://docs.dagger.io/1223/custom-buildkit/). The following covers how to use Dagger with containerized Buildkit using Podman.

## Steps

1. [Install Podman](https://podman.io/getting-started/installation)
1. Run Buildkit using the following, modifying as appropriate for your system: `podman run -d --name buildkitd --privileged moby/buildkit:latest` ([reference](https://github.com/moby/buildkit#podman))
1. [Install Dagger](https://docs.dagger.io/1200/local-dev)
1. Set BUILDKIT_HOST environment variable to podman-container://buildkit , for ex: `export BUILDKIT_HOST=podman-container://buildkit` ([reference](https://docs.dagger.io/1223/custom-buildkit/))
5. Run Dagger commands as necessary.
