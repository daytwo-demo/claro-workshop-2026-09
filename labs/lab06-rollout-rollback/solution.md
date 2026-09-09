# Lab 6: Solución

## Comandos

```bash
oc apply -f manifests/deployment.yaml
oc apply -f manifests/service.yaml
oc apply -f manifests/route.yaml
oc rollout status deployment/podpet

HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"        # "name":"Application version 1"

oc set env deployment/podpet PET_NAME="Application version 2"
oc rollout status deployment/podpet
oc rollout history deployment/podpet
curl "http://${HOST}/api/pet"        # "name":"Application version 2"

oc apply -f broken/deployment-bad-image.yaml
oc rollout status deployment/podpet
oc get pods -l app=podpet
oc describe pod -l app=podpet
# -> ImagePullBackOff en ghcr.io/daytwo-demo/podpet:v9.9.9

oc rollout history deployment/podpet
oc rollout undo deployment/podpet
oc rollout status deployment/podpet
curl "http://${HOST}/api/pet"        # de vuelta a "name":"Application version 2"
```

## Comportamiento esperado durante el rollout roto

Como el Deployment usa la estrategia `RollingUpdate` por defecto con 2
réplicas, OpenShift no da de baja los Pods sanos de la revisión 2 hasta
que suficientes Pods de la revisión 3 estén Ready, lo cual nunca pasa,
ya que la revisión 3 ni siquiera puede hacer pull de su imagen. Los
estudiantes deberían observar que la Route **sigue sirviendo la
versión 2** todo el tiempo, con `oc rollout status` reportando algo
como:

```
Waiting for deployment "podpet" rollout to finish: 1 out of 2
new replicas have been updated...
```

Vale la pena señalar esto explícitamente: la estrategia de rolling
update por defecto es en sí misma una red de seguridad contra un
rollout malo, pero solo funciona si el ReplicaSet viejo todavía tiene
capacidad; no reemplaza rollback de verdad, ya que el Deployment queda
en un estado trabado, a medio actualizar, hasta que alguien actúa.

## Puntos de enseñanza

- `oc rollout undo` apunta a un **Deployment**, no a un Pod: refuerza
  que el rollback opera a nivel de configuración/revisión, nunca a
  nivel de Pod individual.
- `oc rollout history` solo muestra números de revisión por defecto;
  usa `oc rollout history deployment/podpet --revision=<n>` para ver
  exactamente qué cambió en una revisión dada, si los estudiantes
  preguntan.
- Asegúrate de que cada estudiante pueda explicar, sin que se lo
  pidas, por qué `oc delete pod` no habría arreglado el problema de la
  versión 3 (se habría creado un Pod nuevo a partir del mismo template
  roto).
- Es la misma app que en los Labs 3-5, así que si algún estudiante ya
  tiene el hábito de mirar `oc describe pod`, `oc get events` y `oc
  logs --previous` de labs anteriores, este lab premia justamente eso.

## Errores comunes

- Correr `oc rollout undo` más de una vez seguida y pasarse de la
  revisión a la que querían volver: recuerda a los estudiantes que
  `oc rollout undo` retrocede exactamente un paso desde la revisión
  actual, salvo que se dé `--to-revision=<n>`.
- Eliminar Pods manualmente durante el rollout trabado, esperando que
  eso lo "destrabe": no lo hace, porque el ReplicaSet solo recrea el
  mismo Pod roto.

## Reset

```bash
oc apply -f manifests/deployment.yaml
```

O, para eliminar todo lo de este lab por completo:

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml --ignore-not-found
```
