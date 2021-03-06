#!/bin/bash

set -o nounset

# duplicated since it may not be available via fats
travis_fold() {
  local action=$1
  local name=$2
  echo -en "travis_fold:${action}:${name}\r\033[0K"
}

fats_dir=`dirname "${BASH_SOURCE[0]}"`/fats

# script failed, dump debug info
if [ "$TRAVIS_TEST_RESULT" = "1" ]; then
  travis_fold start debug
  sudo free -m -t
  sudo dmesg
  travis_fold end debug
fi

# attempt to cleanup fats
if [ -d "$fats_dir" ]; then
  if [ "$TRAVIS_TEST_RESULT" = "1" ]; then
    travis_fold start system-status
    echo "System status"
    kubectl get deployments,services,pods --all-namespaces || true
    kubectl get pods --all-namespaces --field-selector=status.phase!=Running \
      | tail -n +2 | awk '{print "-n", $1, $2}' | xargs -L 1 kubectl describe pod || true
    kubectl describe node || true
    travis_fold end system-status
  fi

  travis_fold start system-uninstall
  echo "Uninstall riff system"
  riff system uninstall --istio --force || true
  kubectl delete namespace $NAMESPACE || true
  travis_fold end system-uninstall

  source $fats_dir/cleanup.sh
fi
