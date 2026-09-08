#!/usr/bin/env bash
# Checks that the current machine/login is ready for the workshop.
# Safe to run as a student or an instructor. Does not require Docker or
# Podman - only the 'oc' CLI.
#
# Usage:
#   ./scripts/validate-environment.sh

set -uo pipefail

PASS=0
WARN=0
FAIL=0

pass() { echo "  [OK]   $1"; PASS=$((PASS+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "== oc CLI =="
if command -v oc >/dev/null 2>&1; then
  pass "'oc' found: $(command -v oc)"
  oc version --client 2>/dev/null | sed 's/^/         /'
else
  fail "'oc' CLI not found in PATH."
fi
echo

echo "== Login status =="
if oc whoami >/dev/null 2>&1; then
  pass "Logged in as: $(oc whoami)"
else
  fail "Not logged in. Run 'oc login ...' first."
fi
echo

echo "== API reachability =="
if oc get --raw /healthz >/dev/null 2>&1; then
  pass "OpenShift API is reachable."
else
  fail "Could not reach the OpenShift API (oc get --raw /healthz failed)."
fi
echo

echo "== Cluster version =="
CV=""
CV="$(oc get clusterversion version -o jsonpath='{.status.desired.version}' 2>/dev/null || true)"
if [[ -n "${CV}" ]]; then
  pass "Cluster version (ClusterVersion): ${CV}"
else
  SV="$(oc version -o json 2>/dev/null | grep -o '"gitVersion": *"[^"]*"' | tail -n1 | cut -d'"' -f4 || true)"
  if [[ -n "${SV}" ]]; then
    warn "Could not read ClusterVersion (needs extra RBAC) - server version reports: ${SV}"
  else
    fail "Could not determine the cluster version by any method."
  fi
fi
echo

echo "== Route API =="
if oc api-resources --api-group=route.openshift.io 2>/dev/null | grep -q '^routes'; then
  pass "Route API (route.openshift.io) is available."
else
  fail "Route API (route.openshift.io) was not found on this cluster."
fi
echo

echo "== Project creation =="
if oc auth can-i create projectrequests >/dev/null 2>&1; then
  pass "Current user can self-service create projects (create projectrequests: yes)."
else
  warn "Current user cannot self-service create projects. Instructor must run scripts/instructor-setup.sh for each student."
fi
echo

echo "== Image pull check =="
CURRENT_PROJECT="$(oc project -q 2>/dev/null || true)"
if [[ -z "${CURRENT_PROJECT}" ]]; then
  warn "No current project selected - skipping image pull test. Re-run this after 'oc project <name>' to check image pulls."
else
  echo "  Using project '${CURRENT_PROJECT}' for a throwaway pull test..."
  if oc run workshop-image-check \
      --image=docker.io/openshift/hello-openshift:v3.9.0 \
      --restart=Never \
      --command -- /bin/true >/dev/null 2>&1; then
    READY=0
    for _ in $(seq 1 15); do
      PHASE="$(oc get pod workshop-image-check -o jsonpath='{.status.phase}' 2>/dev/null || true)"
      REASON="$(oc get pod workshop-image-check -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || true)"
      if [[ "${PHASE}" == "Succeeded" ]]; then
        READY=1
        break
      fi
      if [[ "${REASON}" == "ImagePullBackOff" || "${REASON}" == "ErrImagePull" ]]; then
        break
      fi
      sleep 2
    done
    if [[ "${READY}" == "1" ]]; then
      pass "Cluster can pull docker.io/openshift/hello-openshift:v3.9.0."
    else
      fail "Cluster could not pull docker.io/openshift/hello-openshift:v3.9.0 - check egress/registry access."
    fi
    oc delete pod workshop-image-check --ignore-not-found=true >/dev/null 2>&1
  else
    fail "Could not even create the test pod - check permissions in project '${CURRENT_PROJECT}'."
  fi
fi
echo

echo "=================================="
echo "Summary: ${PASS} passed, ${WARN} warnings, ${FAIL} failed"
echo "=================================="

if [[ "${FAIL}" -gt 0 ]]; then
  exit 1
fi
exit 0
