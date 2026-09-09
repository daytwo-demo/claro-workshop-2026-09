# Lab 6: Rollout y Rollback

**Duración:** aproximadamente 25-30 minutos

## Objetivo

Realizar una actualización rolling normal, observarla suceder, y
después disparar un rollout fallido y recuperarte de él usando
`oc rollout undo`, no eliminando Pods.

## Escenario

Estás corriendo `podpet` en la versión 1 (usas `PET_NAME` como marcador
de versión, igual que ya hiciste con `RESPONSE` en `hello-openshift`
al principio del workshop). Vas a publicar la versión 2 (un cambio de
configuración de rutina), después vas a intentar publicar la versión 3
(que resulta referenciar una imagen rota), y te vas a recuperar.

## Tasks

### 1. Desplegar la revisión 1

```bash
oc apply -f manifests/deployment.yaml
oc apply -f manifests/service.yaml
oc apply -f manifests/route.yaml

oc rollout status deployment/podpet
HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
# -> "name":"Application version 1"
```

### 2. Publicar la revisión 2

Actualiza el valor de `PET_NAME` a `Application version 2`, ya sea
editando `manifests/deployment.yaml` y reaplicando, o con:

```bash
oc set env deployment/podpet PET_NAME="Application version 2"
```

Observa el rollout:

```bash
oc rollout status deployment/podpet
oc rollout history deployment/podpet
```

Confirma:

```bash
curl "http://${HOST}/api/pet"
# -> "name":"Application version 2"
```

### 3. Publicar una revisión rota

```bash
oc apply -f broken/deployment-bad-image.yaml
```

Observa qué pasa:

```bash
oc rollout status deployment/podpet
oc get pods -l app=podpet
```

El rollout no se completa. Investiga por qué usando las mismas
herramientas del Lab 5 (`oc describe pod`, `oc get events`) antes de
tocar nada. Fíjate si la Route sigue sirviendo tráfico mientras pasa
esto, y piensa en por qué.

### 4. Recuperarte

```bash
oc rollout history deployment/podpet
oc rollout undo deployment/podpet
oc rollout status deployment/podpet
```

### 5. Validar

```bash
curl "http://${HOST}/api/pet"
# -> "name":"Application version 2"
oc get pods -l app=podpet
```

## `oc delete pod` vs `oc rollout restart` vs `oc rollout undo`

Antes de terminar, asegúrate de poder explicar la diferencia entre
estos tres, y cuándo es apropiado cada uno:

- **`oc delete pod <nombre>`**: elimina un Pod. El ReplicaSet del
  Deployment crea inmediatamente un reemplazo usando el Pod template
  *actual*. Esto no arregla nada de un problema de configuración: el
  Pod nuevo va a tener exactamente el mismo bug que el que eliminaste.
  Solo es útil cuando un Pod específico quedó trabado de una forma que
  una configuración sana no debería reproducir (algo poco común, y que
  vale la pena investigar por qué pasó).
- **`oc rollout restart deployment/<nombre>`**: recrea cada Pod usando
  el template *actual* (posiblemente todavía roto). Útil para levantar
  un cambio externo (por ejemplo, el contenido de un Secret montado que
  cambió) que no dispara una revisión nueva por sí solo. No arregla un
  template malo.
- **`oc rollout undo deployment/<nombre>`**: revierte el Pod template
  del Deployment a una revisión anterior. Es el único de los tres que
  realmente cambia la configuración de vuelta a algo que se sabe que
  funciona.

Eliminar Pods nunca es un arreglo para una configuración de Deployment
mal hecha: solo produce otro Pod con el mismo bug.

## Comandos útiles

```bash
oc apply -f <archivo>
oc set env deployment/<nombre> KEY=value
oc rollout status deployment/<nombre>
oc rollout history deployment/<nombre>
oc rollout undo deployment/<nombre>
oc rollout restart deployment/<nombre>
oc describe pod -l app=<nombre>
oc get events --sort-by=.lastTimestamp
```

## Validación

- Después del paso 2, `curl .../api/pet` devuelve
  `"name":"Application version 2"`.
- Después del paso 3, `oc rollout status` no reporta éxito, y puedes
  nombrar la razón específica (a partir de `oc describe pod`/`oc get
  events`) por la que la revisión nueva está fallando.
- Después del paso 4, la Route vuelve a servir `Application version
  2`, y `oc get pods` muestra solo Pods sanos.

## Limpieza

No hace falta antes del Lab 7, que usa su propio nombre de aplicación y
recursos acotados a su propio project. Para eliminar todo lo de este
lab:

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml
```
