#!/usr/bin/bash

set -o nounset
set -o errexit

container=$(buildah from scratch)
buildah commit --rm container localhost/test:latest
