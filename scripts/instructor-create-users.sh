#!/usr/bin/env bash
# Instructor-run. Creates cluster login accounts for students using
# OpenShift's HTPasswd identity provider, and prints the generated
# passwords to a local file for you to distribute securely.
#
# Requires cluster-admin. Never run this against a cluster's OAuth
# config without understanding what identity providers already exist:
# this script reads the current config first and only ever ADDS to it -
# it never removes or replaces an existing identity provider, and it
# merges into (never overwrites) an existing htpasswd Secret.
#
# Usage:
#   ./scripts/instructor-create-users.sh user01 user02 user03
#   ./scripts/instructor-create-users.sh --count 15
#   ./scripts/instructor-create-users.sh --count 15 --prefix alumno
#
# Requires: oc, htpasswd (httpd-tools / apache2-utils), jq, openssl.

set -euo pipefail

IDP_NAME="workshop-htpasswd"
SECRET_NAME="htpass-secret"
SECRET_NS="openshift-config"
OUT_FILE="student-credentials.csv"

usage() {
  echo "Usage: $0 <user1> [user2 ...]" >&2
  echo "       $0 --count N [--prefix user]" >&2
  exit 1
}

USERNAMES=()
COUNT=""
PREFIX="user"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count)
      COUNT="$2"; shift 2 ;;
    --prefix)
      PREFIX="$2"; shift 2 ;;
    -h|--help)
      usage ;;
    *)
      USERNAMES+=("$1"); shift ;;
  esac
done

if [[ -n "$COUNT" ]]; then
  if [[ ${#USERNAMES[@]} -gt 0 ]]; then
    echo "ERROR: no combines nombres explícitos con --count." >&2
    exit 1
  fi
  for i in $(seq -w 1 "$COUNT"); do
    USERNAMES+=("${PREFIX}${i}")
  done
fi

if [[ ${#USERNAMES[@]} -eq 0 ]]; then
  usage
fi

for name in "${USERNAMES[@]}"; do
  if ! [[ "$name" =~ ^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$ ]]; then
    echo "ERROR: nombre de usuario inválido: '$name' (minúsculas, dígitos, guiones)." >&2
    exit 1
  fi
done

for bin in oc htpasswd jq openssl; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "ERROR: falta '$bin' en el PATH." >&2
    exit 1
  fi
done

if ! oc whoami >/dev/null 2>&1; then
  echo "ERROR: no hay sesión de oc iniciada." >&2
  exit 1
fi

if [[ -e "$OUT_FILE" ]]; then
  echo "ERROR: '$OUT_FILE' ya existe en este directorio. Muévelo o" >&2
  echo "elimínalo primero para no pisar credenciales previas por accidente." >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
HTPASSWD_FILE="$WORKDIR/htpasswd"
touch "$HTPASSWD_FILE"

echo "Instructor: $(oc whoami)"
echo "Cluster: $(oc whoami --show-server 2>/dev/null || echo desconocido)"
echo

echo "Descargando el htpasswd existente (si lo hay), para no pisarlo..."
if oc get secret "$SECRET_NAME" -n "$SECRET_NS" >/dev/null 2>&1; then
  oc get secret "$SECRET_NAME" -n "$SECRET_NS" -o jsonpath='{.data.htpasswd}' \
    | base64 -d > "$HTPASSWD_FILE"
  echo "  Secret '$SECRET_NAME' ya existía en '$SECRET_NS' - se conserva su contenido."
else
  echo "  No existía '$SECRET_NAME' - se crea desde cero."
fi

echo
echo "Generando usuarios..."
: > "$OUT_FILE"
echo "username,password" >> "$OUT_FILE"

for name in "${USERNAMES[@]}"; do
  password="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-16)"
  # La password va por stdin (herestring), nunca como argumento: así no
  # queda visible en `ps aux` ni en el argv de ningún proceso.
  htpasswd -Bi "$HTPASSWD_FILE" "$name" <<< "$password"
  echo "${name},${password}" >> "$OUT_FILE"
  echo "  ${name}"
done

echo
echo "Actualizando el Secret '$SECRET_NAME' en '$SECRET_NS'..."
oc create secret generic "$SECRET_NAME" \
  --from-file=htpasswd="$HTPASSWD_FILE" \
  -n "$SECRET_NS" \
  --dry-run=client -o yaml | oc apply -f - >/dev/null

echo "Revisando identityProviders en oauth/cluster..."
oc get oauth cluster -o json > "$WORKDIR/oauth.json"

if jq -e --arg name "$IDP_NAME" \
    '(.spec.identityProviders // []) | map(.name) | index($name)' \
    "$WORKDIR/oauth.json" >/dev/null; then
  echo "  El identity provider '$IDP_NAME' ya estaba configurado - no se toca."
else
  echo "  Agregando el identity provider '$IDP_NAME' (sin tocar los que ya existían)..."
  jq --arg name "$IDP_NAME" --arg secret "$SECRET_NAME" \
    '{
      spec: {
        identityProviders: ((.spec.identityProviders // []) + [{
          name: $name,
          mappingMethod: "claim",
          type: "HTPasswd",
          htpasswd: { fileData: { name: $secret } }
        }])
      }
    }' "$WORKDIR/oauth.json" > "$WORKDIR/patch.json"
  oc patch oauth cluster --type=merge -p "$(cat "$WORKDIR/patch.json")"
fi

echo
echo "Listo. ${#USERNAMES[@]} usuario(s) creado(s)/actualizado(s)."
echo "Credenciales guardadas en: $OUT_FILE"
echo
echo "IMPORTANTE:"
echo "  - No commitees '$OUT_FILE'. Distribuye las credenciales por un canal seguro"
echo "    (no por email/chat en texto plano si podés evitarlo) y borra el archivo"
echo "    local después de repartirlas."
echo "  - El OAuth operator puede tardar 1-2 minutos en aplicar el cambio; los"
echo "    logins nuevos pueden fallar hasta entonces."
echo "  - Esto NO habilita creación self-service de projects. Si tu clúster no la"
echo "    tiene habilitada, seguí usando ./scripts/instructor-setup.sh por estudiante."
