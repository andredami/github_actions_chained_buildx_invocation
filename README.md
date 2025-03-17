# Docker Buildx Multi-Stage Build Scripts using Github Actions

This repository is an example on how to use Docker Buildx for multi-stage builds such that the process is
suitable for both local (Docker Desktop) runs and CI/CD (Github Actions) runs.

## Use case

This repository is relevant if you have multiple Dockerfiles with some referring to others.

For example, you have a `step1.dockerfile` that builds a base image called `step1` and a `step2.dockerfile` that starts `FROM step1` and builds an image called `step2`, which is the actual output of the build process.

**If you are not using `docker buildx bake` build system**, you may have a `build.sh` script that:

1. Calls `docker buildx build` to build `step1` image, then
2. Calls `docker buildx build` to build `step2` image on top of `step1` image.

### Issue

As detailed in [this `buildkit` issue](https://github.com/moby/buildkit/issues/2343), the `docker buildx` build system does not rely on the local Docker daemon to obtain base images. Instead, it uses a separate builder instance that is created and destroyed for each build. This means that the `step1` image built in the first step is **not available** in the second step, unless you are using a local Docker Desktop installation (which is custom built to support this case as a retro-compatibility feature with the legacy `docker build` system).

This means that, in absence of a local Docker Desktop installation, an intermediary registry must be used to store the `step1` image and retrieve it in the second step. Nevertheless, this is overkill and slow for local development.

## Structure of the repository

This repository contains the following files:

- [`build.sh`](./build.sh): the example of a multi-stage build script that supports both local and CI/CD runs. (see the script for more details)
- [`step1.dockerfile`](./step1.dockerfile) and [`step2.dockerfile`](./step2.dockerfile): the example Dockerfiles that build the `step1` and `step2` images, respectively.
- [`.github/workflows/create_and_use_image.yml`](./.github/workflows/create_and_use_image.yml): the Github Actions workflow that builds and uses the image using the multi-stage flow.

## How to use

### Local Docker Desktop

```sh
/bin/sh ./build.sh
```

### Github Actions

Trigger the `create_and_use_image` workflow.

## Details on the solution

This solution is thought such that:

- No modification is needed to any of the Dockerfiles. They can be used as-is for both local and CI/CD runs.
  - i.e., no need to develop or customize the Dockerfiles so that they can be used in CI\CD runs if they were previously thought for local Docker Desktop builds.
- No docker registry is needed for local development, which would slow down the build process without any added value.

## Further suggestions

Using the `docker buildx bake` system is a good idea to avoid the need for a custom script to handle the multi-stage build process.
