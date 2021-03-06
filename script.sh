#!/usr/bin/bash

set -o nounset
set -o errexit

KUBECTL_VERSION=1.18.14
KUSTOMIZE_VERSION=3.8.7
KUBESEAL_VERSION=0.13.1
FLUX_VERSION=0.4.0
KOPS_VERSION=1.20.0-alpha.2
RELEASE_VER=33

function install_packages_scratch {
  local builder=${1}
  local packages=${2}
  local release_ver=${3}
  local mount=$(buildah mount $builder)

  yum install ${packages} -y --installroot $mount --releasever $release_ver \
      --setopt install_weak_deps=false --setopt tsflags=nodocs \
      --setopt override_install_langs=en_US.utf8 \
    && yum clean all -y --installroot $mount --releasever $release_ver
  rm -rf "${mount}/var/cache/yum"
  rm -rf "${mount}/var/cache/dnf"

  buildah unmount $builder
}

builder=$(buildah from scratch)
install_packages_scratch $builder "python awscli" $RELEASE_VER

curl -sSLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod u+x kubectl
buildah copy $builder "kubectl" /bin

curl -sSL0 https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar -zx -C ./
chmod +x kustomize
buildah copy $builder "kustomize" /bin

curl -sSLO https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-linux-amd64
mv kubeseal-linux-amd64 kubeseal
chmod u+x kubeseal
buildah copy $builder "kubeseal" /bin

curl -sSL0 https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz | tar -zx -C ./
chmod +x flux
buildah copy $builder "flux" /bin

curl -sSLO https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64
mv kops-linux-amd64 kops
chmod +x kops
buildah copy $builder "kops" /bin

buildah commit --rm $builder quay.io/jam01/tavros-base:latest
