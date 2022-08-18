#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-18 16:53:40 +0100 (Thu, 18 Aug 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds empty namespaces in the current Kubernetes cluster context and deletes them

Kubectl must be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

kube_config_isolate

timestamp "Getting list of namespaces"
#kubectl get ns -o name |
#sed 's|namespace/||' |
kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' |
while read -r namespace; do
    if [[ "$namespace" =~ ^kube- ]]; then
        continue
    fi
    timestamp "Checking namespace '$namespace'"
    # quicker, but doesn't return all objects - should return the usual candidates though
    objects="$(kubectl get all -n "$namespace" -o name)"
    # slow but safer
    #objects="$("$srcdir/kubectl_get_all.sh" -n "$namespace" | sed 's/#.*//| /^[[:space:]]*$/d')"
    if [ -z "$objects" ]; then
        timestamp "Deleting empty namespace '$namespace'"
        kubectl delete namespace "$namespace"
    fi
done
