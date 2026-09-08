#!/usr/bin/env bash
# Instructor-run full reset for a single student's project. Use this when
# a student's own ./scripts/reset-student.sh cannot run (e.g. they lack
# permission), or when a project is in a state you'd rather rebuild than
# repair.
#
# Only ever touches ocp-workshop-<student_id>. Never deletes the project
# of any other student, and never operates on more than one project per
# invocation.
#
# Usage:
#   ./scripts/instructor-reset.sh user01
#   ./scripts/instructor-reset.sh user01 --full   # also deletes and recreates the project itself

set -euo pipefail

STUDENT_ID="${1:-}"
MODE="${2:-}"

if [[ -z "${STUDENT_ID}" ]]; then
  echo "Usage: $0 <student_id> [--full]" >&2
  echo "Example: $0 user01" >&2
  echo "  --full also deletes and recreates the project itself, instead of" >&2
  echo "  just clearing lab-created objects inside it." >&2
  exit 1
fi

if ! [[ "${STUDENT_ID}" =~ ^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$ ]]; then
  echo "ERROR: student id '${STUDENT_ID}' is not valid." >&2
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
  echo "Project '${PROJECT}' does not exist - nothing to reset. Run instructor-setup.sh instead." >&2
  exit 1
fi

if [[ "${MODE}" == "--full" ]]; then
  echo "Deleting and recreating project '${PROJECT}'..."
  oc delete project "${PROJECT}"
  echo "Waiting for project '${PROJECT}' to be fully removed..."
  for _ in $(seq 1 30); do
    if ! oc get project "${PROJECT}" >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
  oc new-project "${PROJECT}" --display-name="OpenShift Workshop - ${STUDENT_ID}" >/dev/null
else
  echo "Clearing lab-created objects in project '${PROJECT}'..."
  oc delete deployment,service,route,configmap,secret,pod \
    -l lab -n "${PROJECT}" --ignore-not-found=true
fi

echo "Applying Lab 1 sample resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab01-cluster-exploration/manifests/sample-resources.yaml"

echo "Applying Lab 5 scenario resources..."
for d in imagepullbackoff crashloopbackoff service-no-endpoints readiness-failure; do
  oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab05-troubleshooting/scenarios/${d}/"
done

echo "Applying Lab 7 incident resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab07-final-incident/scenario/"

echo
echo "Project '${PROJECT}' has been reset to its known starting state."
