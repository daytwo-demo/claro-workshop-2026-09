#!/usr/bin/env bash
# Student-run reset. Restores your project to its known starting state:
# removes every object created by the labs, then re-applies the resources
# that need to already exist before Lab 1, Lab 5, and Lab 7 (see
# scripts/instructor-setup.sh for what those are).
#
# Your project has the same name as your login user, so this script infers
# it from `oc whoami`. It only ever touches your own project, never any
# other student's.
#
# Usage:
#   ./scripts/reset-student.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v oc >/dev/null 2>&1; then
  echo "ERROR: 'oc' CLI not found in PATH." >&2
  exit 1
fi

if ! oc whoami >/dev/null 2>&1; then
  echo "ERROR: not logged in. Open the Web Terminal or run 'oc login ...' first." >&2
  exit 1
fi

USERNAME="$(oc whoami)"
PROJECT="${USERNAME}"

if ! oc get project "${PROJECT}" >/dev/null 2>&1; then
  echo "ERROR: project '${PROJECT}' does not exist or you cannot see it." >&2
  echo "Ask your instructor to run: ./scripts/instructor-setup.sh ${USERNAME}" >&2
  exit 1
fi

echo "Resetting project '${PROJECT}' only."

echo "Removing all lab-created objects..."
oc delete deployment,service,route,configmap,secret,pod \
  -l lab -n "${PROJECT}" --ignore-not-found=true

echo "Re-applying Lab 1 sample resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab01-cluster-exploration/manifests/sample-resources.yaml"

echo "Re-applying Lab 5 scenario resources..."
for d in imagepullbackoff crashloopbackoff service-no-endpoints readiness-failure; do
  oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab05-troubleshooting/scenarios/${d}/"
done

echo "Re-applying Lab 7 incident resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab07-final-incident/scenario/"

echo
echo "Project '${PROJECT}' has been reset to its known starting state."
