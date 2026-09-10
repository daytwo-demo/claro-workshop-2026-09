# OpenShift Operations Fundamentals

Un workshop práctico de dos días y 8 horas para administradores de
sistemas Linux y personal de IT Operations con poca o ninguna
experiencia en Kubernetes/OpenShift.

## Propósito

Este workshop enseña **operación** de OpenShift, no desarrollo de
aplicaciones. Al terminar, los estudiantes van a poder:

- Navegar un clúster de OpenShift usando `oc` y la consola web.
- Desplegar una imagen de contenedor existente y ya publicada (sin
  builds, sin Dockerfiles).
- Configurar aplicaciones con ConfigMaps y Secrets.
- Configurar e interpretar readiness/liveness probes.
- Diagnosticar los modos de falla más comunes (ImagePullBackOff,
  CrashLoopBackOff, Services sin endpoints, fallas de readiness) usando
  `oc describe`, `oc logs` y `oc get events`.
- Realizar rollouts y rollbacks seguros de un Deployment.
- Ejecutar un pase completo de respuesta a incidentes sobre una
  aplicación caída, desde la Route hasta los logs del Pod.

Ningún lab de este repositorio construye una imagen de contenedor. Cada
aplicación es una imagen existente, extraída de un registro público.

## Prerrequisitos

Ver [`docs/prerequisites.md`](docs/prerequisites.md) para la lista
completa. En resumen, cada estudiante necesita:

- Acceso a un clúster de OpenShift (4.18+) y un juego de credenciales.
- Un navegador web. El **Web Terminal** de la consola web da acceso a
  `oc` sin instalar nada; el CLI `oc` local es una alternativa opcional.
- Un project (namespace) con el mismo nombre que tu usuario, provisto
  por el instructor con los permisos necesarios.
- Ningún task de estudiante requiere ni asume acceso de cluster-admin.

## Cómo entrar

No hace falta instalar nada localmente. Entra a la consola web del
clúster (te la da tu instructor), inicia sesión con tu usuario y
contraseña, y abre el **Web Terminal** desde el ícono de terminal
(`>_`) en la barra superior. Ese Web Terminal ya trae `oc` autenticado
con tu usuario.

Confirma que iniciaste sesión con el usuario esperado:

```bash
oc whoami
```

Si prefieres usar tu propio `oc` local en vez del Web Terminal, también
puedes:

```bash
oc login --server=<cluster-api-url> -u <username> -p <password>
# o, con un token copiado desde la consola web:
oc login --server=<cluster-api-url> --token=<token>
```

## Tu project

Cada ejercicio de este workshop está acotado a un project (namespace)
único para ti. Tu project se llama **exactamente igual que tu usuario de
login**: si entras como `user07`, tu project es `user07`. Nada se
comparte entre estudiantes, y ningún lab hardcodea un solo namespace
para todos.

Tu instructor ya creó ese project y te dio los permisos que necesitas,
y precargó algunos recursos que ciertos labs necesitan. No tienes que
crear el project ni definir ninguna variable.

Confirma siempre que estás en el project correcto antes de empezar un
lab:

```bash
oc project
```

## Clona el repositorio del workshop

Los labs aplican manifiestos que viven en este repositorio. Clónalo una
vez, dentro del Web Terminal (o en tu máquina, si usas `oc` local):

```bash
git clone https://github.com/daytwo-demo/claro-workshop-2026-09.git
cd claro-workshop-2026-09
```

Cada lab asume que estás dentro de su propia carpeta antes de correr los
comandos. Por ejemplo, el Lab 3 se corre desde
`labs/lab03-configmaps-secrets`. Cada README de lab usa rutas relativas
(`manifests/...`, `broken/...`, `scenario/...`) a esa carpeta.

## Orden y duración de los labs

Trabaja los labs en orden: cada uno reutiliza lo aprendido en los
anteriores, y varios continúan el estado del lab previo (por ejemplo,
Labs 3 y 4 usan el mismo Deployment `podpet`).

| # | Lab | Duración aprox. |
|---|-----|-------------------|
| 1 | [Exploración del clúster](labs/lab01-cluster-exploration/README.md) | 25-30 min |
| 2 | [Desplegar una aplicación existente](labs/lab02-deploy-application/README.md) | 35-40 min |
| 3 | [ConfigMaps y Secrets](labs/lab03-configmaps-secrets/README.md) | 30 min |
| 4 | [Health probes](labs/lab04-health-probes/README.md) | 30-35 min |
| 5 | [Troubleshooting](labs/lab05-troubleshooting/README.md) | 45-50 min |
| 6 | [Rollout y rollback](labs/lab06-rollout-rollback/README.md) | 25-30 min |
| 7 | [Incidente final](labs/lab07-final-incident/README.md) | 30 min |

Tiempo práctico total: entre 3.5 y 4 horas aproximadamente, dejando
espacio en los dos días para demos del instructor, discusión y
descansos.

Una división sugerida:

- **Día 1**: Labs 1-4 (fundamentos: explorar, desplegar, configurar,
  probes).
- **Día 2**: Labs 5-7 (troubleshooting, rollout/rollback, incidente
  final).

## Aplicaciones usadas

- **Labs 1-2**: `docker.io/openshift/hello-openshift:v3.9.0`,
  deliberadamente mínima, para aprender la mecánica de
  Deployment/Service/Route/scaling sin distracciones.
- **Labs 3-7**: `ghcr.io/daytwo-demo/podpet:v1.0.1` (PodPet), una
  mascota virtual (Java/Quarkus, sin base de datos) con su propia UI,
  API, y un liveness check real ligado a sus propias stats. El código
  fuente vive en
  [`claro-workshop-2026-09-app`](https://github.com/daytwo-demo/claro-workshop-2026-09-app).
- **Lab 5 (escenario de CrashLoop)**: `registry.access.redhat.com/ubi9/ubi-minimal:9.4`,
  una imagen base sin servidor HTTP, para que el foco sea la mecánica de
  un crash loop y no la aplicación.

Todas son imágenes ya publicadas: ningún lab las construye.

## Reiniciar tu entorno

Si un lab deja tu project en un estado que no entiendes, o simplemente
quieres empezar de nuevo, corre:

```bash
./scripts/reset-student.sh
```

El script detecta tu project a partir de `oc whoami`, y lo restaura a
su estado inicial conocido, sin tocar el project de ningún otro
estudiante. Si el script reporta que no tiene permiso para limpiar tu
project, pide a tu instructor que corra
`scripts/instructor-reset.sh <tu-usuario>` en su lugar.

El README de cada lab también tiene su propia sección de **Limpieza**
para una limpieza acotada a ese lab, que no requiere un reinicio
completo.

## Lo que este workshop no es

Este no es un workshop de desarrollo de contenedores ni de CI/CD. No
vas a usar Source-to-Image (S2I), BuildConfig, builds de ImageStream,
Docker, Podman, ni ningún Dockerfile/Containerfile. Cada imagen de
aplicación ya existe publicada en un registro público antes de que
empiece el workshop.

## Estructura del repositorio

```
docs/                    Prerrequisitos, guía del instructor, chuleta de troubleshooting
labs/lab01.../            Exploración del clúster
labs/lab02.../            Desplegar una aplicación existente
labs/lab03.../            ConfigMaps y Secrets
labs/lab04.../            Health probes
labs/lab05.../            Troubleshooting (cuatro escenarios)
labs/lab06.../            Rollout y rollback
labs/lab07.../            Incidente final
scripts/                  Scripts de provisioning del instructor, reset y validación
```

## Repositorios relacionados

- [`claro-workshop-2026-09-showroom`](https://github.com/daytwo-demo/claro-workshop-2026-09-showroom):
  esta misma guía de labs en formato web navegable, publicada en
  https://daytwo-demo.github.io/claro-workshop-2026-09-showroom/.
- [`claro-workshop-2026-09-app`](https://github.com/daytwo-demo/claro-workshop-2026-09-app):
  código fuente y Dockerfile de PodPet, la mascota virtual (Java/Quarkus,
  sin base de datos) que se usa desde el Lab 3 en adelante. Muestra cómo
  se construye y publica una imagen como esta, o como `hello-openshift`,
  antes de que el workshop las use: ningún lab construye nada.
