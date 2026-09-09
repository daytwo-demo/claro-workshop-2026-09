# Prerrequisitos

## Clúster

- OpenShift Container Platform 4.18 o superior.
- Acceso de red desde las laptops de los estudiantes hacia la API del
  clúster y hacia el dominio wildcard de las rutas
  (`*.apps.<cluster-domain>`).
- El clúster debe poder hacer pull desde `docker.io` y
  `registry.access.redhat.com` (no hace falta un mirror de registro
  desconectado/air-gapped para este workshop, salvo que tu entorno ya
  tenga uno).
- Cada estudiante necesita un project (namespace) donde pueda crear
  recursos. No se requiere cluster-admin para ningún task de
  estudiante. Si tu clúster no permite creación self-service de
  projects, usa `scripts/instructor-setup.sh` para provisionarlos de
  antemano.

## Estación de trabajo del estudiante

Dos formas de darles acceso a `oc`, elige una:

### Opción A: CLI local

- CLI `oc` instalado. Si es posible, alinea la versión del cliente con
  la versión menor del clúster; un cliente una versión atrás o adelante
  de un servidor 4.18+ funciona bien para todo lo de este workshop.
- Una terminal (bash o zsh). Todos los comandos de ejemplo usan sintaxis
  bash.
- `curl`, para probar Routes desde la línea de comandos.

### Opción B: Web Terminal (cero instalación local)

Si no quieres que los estudiantes instalen nada en su laptop, instala el
**Web Terminal Operator** en el clúster (una sola vez, antes del
workshop):

1. Como cluster-admin, en la consola web: **OperatorHub** → buscar
   "Web Terminal" → **Install** (dejar los valores por defecto). Esto
   instala automáticamente el DevWorkspace Operator como dependencia.
2. Recarga la consola: aparece un ícono de terminal (`>_`) en la barra
   superior para todos los usuarios.

Cada estudiante hace clic en ese ícono y obtiene una terminal real
dentro del navegador, ya autenticada como él mismo, con `oc` (y
`kubectl`, `helm`, etc.) preinstalados. Solo necesita un navegador.

La sesión de la terminal tiene un timeout por inactividad configurable
(vía un recurso `DevWorkspaceOperatorConfig`). Pruébalo antes del
workshop: deja una terminal sin tocar unos minutos y confirma que no se
corte antes de que un estudiante típico llegue a usarla otra vez; este
workshop tiene bastante lectura entre un comando y el siguiente.

### En ambos casos

- Un navegador web moderno, para las partes del workshop que usan la
  consola web de OpenShift.
- No se requiere instalar Docker ni Podman. Este workshop nunca
  construye ni corre una imagen de contenedor local.

## Cuentas

- Un juego de credenciales de clúster por estudiante (usuario/password,
  o un token copiado desde la consola web para `oc login
  --token=...`).
- La URL de la consola web del clúster.

Si tu clúster todavía no tiene cuentas para los estudiantes y no quieres
depender de un identity provider externo (LDAP, GitHub, Google, etc.),
`scripts/instructor-create-users.sh` crea usuarios vía el identity
provider HTPasswd nativo de OpenShift:

```bash
./scripts/instructor-create-users.sh --count 15
# o con nombres explícitos:
./scripts/instructor-create-users.sh user01 user02 user03
```

Requiere cluster-admin y las herramientas `htpasswd`, `jq` y `openssl`
en la máquina desde la que lo corres. Es seguro de correr en un clúster
que ya tiene otros identity providers configurados: lee la
configuración de `oauth/cluster` y el Secret `htpass-secret` existentes
antes de tocar nada, y solo **agrega** usuarios y el identity provider
`workshop-htpasswd` si todavía no está - nunca reemplaza ni borra un
identity provider o un usuario que ya existía. Las contraseñas
generadas quedan en `student-credentials.csv` (ya está en
`.gitignore`); repártelas por un canal seguro y borra el archivo
después.

## Antes del día uno

Corre la verificación de entorno desde una máquina con `oc` instalado
y con sesión iniciada:

```bash
./scripts/validate-environment.sh
```

Esto confirma que `oc` está presente, que la API es alcanzable, que
existe la Route API, que se puede determinar la versión del clúster, y
(donde los permisos lo permitan) que la creación de projects y el pull
de imágenes funcionan. Corrige cualquier hallazgo antes de que lleguen
los estudiantes.

## Lo que los estudiantes NO necesitan

- Privilegios de cluster-admin.
- Docker o Podman instalado localmente.
- Ninguna experiencia previa escribiendo un Dockerfile/Containerfile:
  este workshop nunca usa uno.
- Experiencia previa con Kubernetes/OpenShift. Ese es justamente el
  punto del workshop.
