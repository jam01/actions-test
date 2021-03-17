#!/usr/bin/bash

set -o nounset
set -o errexit

builder=$(buildah from scratch)
mount=$(buildah mount $builder)
buildah unmount $builder
buildah copy $builder requirements.txt /
buildah commit --rm $builder localhost/test:latest
