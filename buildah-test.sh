#!/usr/bin/bash

set -o nounset
set -o errexit

builder=$(buildah from scratch)
mount=$(buildah mount $builder)
buildah unmount $builder
buildah commit localhost/test:latest
