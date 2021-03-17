#!/usr/bin/env bash

set -o nounset
set -o errexit

IMAGE_NAME=ghcr.io/ms3inc/tavros-buildtools
IMAGE_VERSION=0.6.0

KUBECTL_VERSION=1.18.14
KUSTOMIZE_VERSION=3.8.7
KUBESEAL_VERSION=0.13.1
FLUX_VERSION=0.4.0
KOPS_VERSION=1.20.0-alpha.2
YQ_VERSION=4.2.0
DECK_VERSION=1.5.0

function dnf_install_on {
  local container=${1}
  local packages=${2}
  local mount=$(buildah mount $container)
  local installer_mount=/mnt/container
  export $(podman run fedora:latest grep VERSION_ID /etc/os-release)

  podman run --volume ${mount}:${installer_mount}:rw fedora:latest bash -c "yum install --quiet -y ${packages} \
      --installroot ${installer_mount} --releasever $VERSION_ID \
      --setopt install_weak_deps=false --setopt tsflags=nodocs \
      --setopt override_install_langs=en_US.utf8 \
    && yum clean all -y --installroot $installer_mount --releasever $VERSION_ID
  rm -rf ${installer_mount}/var/cache/yum
  rm -rf ${installer_mount}/var/cache/dnf"

  buildah unmount $container
}

function pip_install_on {
  local container=${1}
  local packages=${2}
  local mount=$(buildah mount $container)

  PYTHONUSERBASE=${mount}/usr/local ANSIBLE_SKIP_CONFLICT_CHECK=1 pip install --user --upgrade --ignore-installed --no-cache-dir $packages

  buildah unmount $container
}

container=$(buildah from scratch)
dnf_install_on $container "python awscli git"
pip_install_on $container "-r requirements.txt"

curl -sSLO "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod u+x kubectl
buildah copy $container "kubectl" /usr/local/bin/

curl -sSL0 "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar -zx -C ./
chmod +x kustomize
buildah copy $container "kustomize" /usr/local/bin/

curl -sSLO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-linux-amd64"
mv kubeseal-linux-amd64 kubeseal
chmod u+x kubeseal
buildah copy $container "kubeseal" /usr/local/bin/

curl -sSL0 "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" | tar -zx -C ./
chmod +x flux
buildah copy $container "flux" /usr/local/bin/

curl -sSLO "https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64"
mv kops-linux-amd64 kops
chmod +x kops
buildah copy $container "kops" /usr/local/bin/

curl -LO "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
mv yq_linux_amd64 yq
chmod +x yq
buildah copy $container "yq" /usr/local/bin/

curl -sSL0 "https://github.com/Kong/deck/releases/download/v${DECK_VERSION}/deck_${DECK_VERSION}_linux_amd64.tar.gz" | tar -zx -C ./
chmod +x deck
buildah copy $container "deck" /usr/local/bin/

buildah commit --rm $container $IMAGE_NAME:latest
buildah tag $IMAGE_NAME:latest $IMAGE_NAME:$IMAGE_VERSION
