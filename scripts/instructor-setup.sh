#!/usr/bin/env bash
# Instructor-run setup for a single student's project. Safe to run more
# than once for the same student (idempotent) and only ever touches that
# one student's project.
#
# Creates ocp-workshop-<student_id> if it doesn't already exist, and
# pre-loads the resources that must already be present before Lab 1,
# Lab 5, and Lab 7 start. Students never need to apply these manifests
# themselves.
#
# Usage:
#   ./scripts/instructor-setup.sh user01

set -euo pipefail

STUDENT_ID="${1:-}"

if [[ -z "${STUDENT_ID}" ]]; then
  echo "Usage: $0 <student_id>" >&2
  echo "Example: $0 user01" >&2
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

if ! oc whoami >/dev/null 2>&1; then
  echo "ERROR: not logged in. Run 'oc login ...' first." >&2
  exit 1
fi

echo "Instructor: $(oc whoami)"
echo "Provisioning project: ${PROJECT}"

if oc get project "${PROJECT}" >/dev/null 2>&1; then
  echo "Project '${PROJECT}' already exists."
else
  echo "Creating project '${PROJECT}'..."
  if ! oc new-project "${PROJECT}" --display-name="OpenShift Workshop - ${STUDENT_ID}" >/dev/null; then
    echo "ERROR: could not create project '${PROJECT}'." >&2
    echo "Your account needs permission to create projects on behalf of students." >&2
    exit 1
  fi
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
echo "Project '${PROJECT}' is ready."
echo "The student should run: oc project ${PROJECT}"
