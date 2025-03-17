#!/bin/sh

# Build script running a multi-stage Docker build
# Supports:
#   * LOCAL build (default): can natively run on machines that have Docker BuildKit driver tied to 'docker'
#   * Buildx build: can run on machines that DO NOT have Docker BuildKit driver tied to 'docker' and requires
#       --intermediary-registry <registry> - specify an intermediary registry to push build step images to
#                                            (optional, default: none, use local)


#####################
# Utility functions #
#####################

get_registry_image_tag() {
  local image_tag=$1
  local registry=$2
  if [ ! -z "$registry" ]; then
    echo "${registry}/${image_tag}"
  else
    echo "${image_tag}"
  fi
}

depends_on_by_registry() {
  local image_name=$1
  local registry=$2
  if [ ! -z "$registry" ]; then
    echo "--build-context ${image_name}=docker-image://$(get_registry_image_tag $image_name $registry)"
  else
    # No need to specify any intermediary registry override
    echo ""
  fi
}

###########################
# Script argument parsing #
###########################

REGISTRY=""
while [ "$1" != "" ]; do
    case $1 in
        --intermediary-registry ) shift
                                  REGISTRY=$1
                                  ;;
        * )                       echo "Invalid argument: $1"
                                  exit 1
    esac
    shift
done

get_image_tag() {
  get_registry_image_tag $1 $REGISTRY
}

depends_on() {
  depends_on_by_registry $1 $REGISTRY
}


################
# Build stages #
################

### TEMPLATES:
###  - Pre-requisites (any docker image that will be used by other images later in the multi-stage build)
###         STEP<N>_IMAGE_NAME="<the-name-of-the-image>"
###         docker buildx build \
###           --load \
###           ${REGISTRY:+--push }\
###           -t $(get_registry_image_tag $STEP<N>_IMAGE_NAME) \
###           <... dependencies ..>
###           <... actual build argument ...>
###
###  - Final build product (any docker image that will not be used by other images later in the multi-stage build)
###         OUT_IMAGE_NAME="<the-name-of-the-image>"
###         docker buildx build \
###           --load \
###           -t $OUT_IMAGE_NAME \
###           <... dependencies ..>
###           <... actual build argument ...>
###  - Dependencies (add to any build command that requires a pre-requisite build)
###         $(depends_on $STEP<N>_IMAGE_NAME)

# Example multi-stage build

# Pre-requisite build
STEP1_IMAGE_NAME="step1"
docker buildx build \
  --load \
  ${REGISTRY:+--push }\
  -t $(get_image_tag $STEP1_IMAGE_NAME) \
  --platform linux/amd64 \
  -f $STEP1_IMAGE_NAME.dockerfile \
  .

# Final build
OUT_IMAGE_NAME="step2"
docker buildx build \
  --load \
  -t $OUT_IMAGE_NAME \
  $(depends_on $STEP1_IMAGE_NAME) \
  --platform linux/amd64 \
  -f $OUT_IMAGE_NAME.dockerfile \
  .
