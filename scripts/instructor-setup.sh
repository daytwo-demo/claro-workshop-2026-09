#!/usr/bin/env bash
# Instructor-run setup for a single student. Creates a project whose name
# is exactly the student's login username, grants that user access to it,
# and pre-loads the resources that must already be present before Lab 1,
# Lab 5, and Lab 7 start. Students never need to apply these manifests
# themselves, and never create their own project.
#
# Safe to run more than once for the same student (idempotent), and it
# only ever touches that one student's project.
#
# Usage:
#   ./scripts/instructor-setup.sh user01

set -euo pipefail

USERNAME="${1:-}"

if [[ -z "${USERNAME}" ]]; then
  echo "Usage: $0 <username>" >&2
  echo "Example: $0 user01" >&2
  echo "The username must match the student's login user; the project" >&2
  echo "will have exactly that name." >&2
  exit 1
fi

if ! [[ "${USERNAME}" =~ ^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$ ]]; then
  echo "ERROR: username '${USERNAME}' is not valid." >&2
  echo "Use lowercase letters, digits, and hyphens only (e.g. user01)." >&2
  exit 1
fi

PROJECT="${USERNAME}"
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
  if ! oc new-project "${PROJECT}" --display-name="OpenShift Workshop - ${USERNAME}" >/dev/null; then
    echo "ERROR: could not create project '${PROJECT}'." >&2
    echo "Your account needs permission to create projects on behalf of students." >&2
    exit 1
  fi
fi

echo "Granting user '${USERNAME}' admin access to '${PROJECT}'..."
oc adm policy add-role-to-user admin "${USERNAME}" -n "${PROJECT}" >/dev/null

echo "Applying Lab 1 sample resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab01-cluster-exploration/manifests/sample-resources.yaml"

echo "Applying Lab 5 scenario resources..."
for d in imagepullbackoff crashloopbackoff service-no-endpoints readiness-failure; do
  oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab05-troubleshooting/scenarios/${d}/"
done

echo "Applying Lab 7 incident resources..."
oc apply -n "${PROJECT}" -f "${REPO_ROOT}/labs/lab07-final-incident/scenario/"

echo
echo "Project '${PROJECT}' is ready for ${USERNAME}."
echo "The student should run: oc project ${PROJECT}"
