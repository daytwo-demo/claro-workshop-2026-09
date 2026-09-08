#!/usr/bin/env bash
# Student-run setup. Creates (or switches into) your own workshop project.
# Does not require cluster-admin - only the ability to create your own
# project, which most OpenShift clusters grant by default.
#
# Usage:
#   export STUDENT_ID=user01
#   ./scripts/setup-student.sh
# or:
#   ./scripts/setup-student.sh user01

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

if ! command -v oc >/dev/null 2>&1; then
  echo "ERROR: 'oc' CLI not found in PATH." >&2
  exit 1
fi

if ! oc whoami >/dev/null 2>&1; then
  echo "ERROR: not logged in. Run 'oc login ...' first." >&2
  exit 1
fi

echo "Logged in as: $(oc whoami)"
echo "Target project: ${PROJECT}"

if oc get project "${PROJECT}" >/dev/null 2>&1; then
  echo "Project '${PROJECT}' already exists - switching to it."
  oc project "${PROJECT}"
else
  echo "Creating project '${PROJECT}'..."
  if ! oc new-project "${PROJECT}" --display-name="OpenShift Workshop - ${STUDENT_ID}"; then
    echo >&2
    echo "ERROR: could not create project '${PROJECT}'." >&2
    echo "Your account may not have self-service project creation enabled." >&2
    echo "Ask your instructor to run: ./scripts/instructor-setup.sh ${STUDENT_ID}" >&2
    exit 1
  fi
fi

echo
echo "Ready. You are now working in project: $(oc project -q)"
