#!/usr/bin/env bash
# Student-run reset. Restores your project to its known starting state:
# removes every object created by the labs, then re-applies the resources
# that need to already exist before Lab 1, Lab 5, and Lab 7 (see
# scripts/instructor-setup.sh for what those are).
#
# Only ever touches your own project (ocp-workshop-<STUDENT_ID>). Never
# touches any other student's project.
#
# Usage:
#   export STUDENT_ID=user01
#   ./scripts/reset-student.sh
# or:
#   ./scripts/reset-student.sh user01

set -euo pipefail

STUDENT_ID="${1:-${STUDENT_ID:-}}"

if [[ -z "${STUDENT_ID}" ]]; then
  echo "ERROR: STUDENT_ID is not set." >&2
  echo "Usage: STUDENT_ID=user01 $0   (or: $0 user01)" >&2
  exit 1
fi

if ! [[ "${STUDENT_ID}" =~ ^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$ ]]; then
  echo "ERROR: STUDENT_ID '${STUDENT_ID}' is not valid." >&2
  echo "Use lowercase letters, digits, and hyphens only (e.g. user01)." >&2
  exit 1
fi

PROJECT="ocp-workshop-${STUDENT_ID}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v oc >/dev/null 2>&1; then
  echo "ERROR: 'oc' CLI not found in PATH." >&2
  exit 1
fi

if ! oc get project "${PROJECT}" >/dev/null 2>&1; then
  echo "ERROR: project '${PROJECT}' does not exist or you cannot see it." >&2
  echo "Run ./scripts/setup-student.sh first." >&2
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
