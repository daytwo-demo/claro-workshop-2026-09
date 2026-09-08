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
- El CLI `oc` instalado localmente, en una versión igual o cercana a la
  del clúster.
- Permiso para crear un Project (namespace) propio, o un instructor que
  lo cree en su nombre.
- Ningún task de estudiante requiere ni asume acceso de cluster-admin.

## Cómo iniciar sesión

```bash
oc login --server=<cluster-api-url> -u <username> -p <password>
# o, con un token copiado desde la consola web:
oc login --server=<cluster-api-url> --token=<token>
```

Confirma que iniciaste sesión con el usuario esperado:

```bash
oc whoami
```

## Definir tu STUDENT_ID

Cada ejercicio de este workshop está acotado a un project (namespace)
único para ti. Nada se comparte entre estudiantes, y ningún lab
hardcodea un solo namespace para todos.

Define esto una vez por sesión de terminal, antes de empezar cualquier
lab:

```bash
export STUDENT_ID=user01
```

Usa el identificador que te asignó tu instructor (por ejemplo `user07`,
`jdoe`, etc). Todos los scripts e instrucciones de los labs derivan el
nombre de tu project a partir de él:

```
ocp-workshop-${STUDENT_ID}
```

Es decir, `STUDENT_ID=user01` corresponde al project
`ocp-workshop-user01`.

## Cómo se crea tu project

Según cómo esté configurado el clúster de tu instructor, una de estas
dos cosas es cierta:

1. **Self-service**: creas tu propio project corriendo
   `scripts/setup-student.sh`, que ejecuta `oc new-project
   ocp-workshop-${STUDENT_ID}` en tu nombre.
2. **Provisto por el instructor**: tu instructor ya corrió
   `scripts/instructor-setup.sh ${STUDENT_ID}` por ti, lo que creó el
   project y precargó algunos recursos que ciertos labs necesitan. En
   ese caso, solo corre `oc project ocp-workshop-${STUDENT_ID}` para
   entrar en él.

De cualquier forma, confirma siempre que estás en el project correcto
antes de empezar un lab:

```bash
oc project
```

## Orden y duración de los labs

Trabaja los labs en orden. Cada uno construye sobre el estado que dejó
el anterior.

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

## Reiniciar tu entorno

Si un lab deja tu project en un estado que no entiendes, o simplemente
quieres empezar de nuevo, corre:

```bash
./scripts/reset-student.sh ${STUDENT_ID}
```

Esto restaura tu project a su estado inicial conocido, sin tocar el
project de ningún otro estudiante. Si el script reporta que no tiene
permiso para recrear tu project, pide a tu instructor que corra
`scripts/instructor-reset.sh ${STUDENT_ID}` en su lugar.

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
scripts/                  Scripts de setup, reset y validación
```

## Repositorios relacionados

- [`claro-workshop-2026-09-showroom`](https://github.com/daytwo-demo/claro-workshop-2026-09-showroom):
  esta misma guía de labs en formato web navegable, publicada en
  https://daytwo-demo.github.io/claro-workshop-2026-09-showroom/.
- [`claro-workshop-2026-09-app`](https://github.com/daytwo-demo/claro-workshop-2026-09-app):
  código fuente y Dockerfile de PodPet, una app de ejemplo (Java/Quarkus,
  sin base de datos) que muestra cómo se construye una imagen como
  `hello-openshift` antes de que este workshop la use. Ningún lab la
  referencia todavía; es un recurso opcional para instructores.
