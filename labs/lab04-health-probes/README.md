# Lab 4: Health Probes

**Duración:** aproximadamente 30-35 minutos

## Objetivo

Agregar readiness y liveness probes al Deployment `podpet`, confirmar
que funcionan, romper la readiness a propósito por un error de
configuración, y provocar una falla de liveness *real* (no un typo de
puerto) descuidando la mascota. Vas a diagnosticar cada una de la misma
forma en que lo harías en producción: a partir de `oc get pods`, `oc
describe pod` y events, no leyendo el manifiesto primero.

## Escenario

Hasta ahora, OpenShift solo sabía si el proceso de tu contenedor estaba
corriendo. No tenía idea de si la aplicación de adentro realmente
podía atender tráfico, ni de si "estaba bien" en algún sentido más
profundo. Los probes cierran esa brecha:

- Un **readiness probe** le dice a OpenShift si este Pod debería
  recibir tráfico a través de un Service en este momento. Un Pod puede
  estar `Running` y aun así estar `NotReady`.
- Un **liveness probe** le dice a OpenShift si el contenedor necesita
  reiniciarse porque quedó trabado, o porque la aplicación misma
  reporta que no está bien.

PodPet expone dos endpoints de salud reales, provistos por Quarkus:

- `/q/health/ready`: siempre responde `UP`.
- `/q/health/live`: responde `UP` normalmente, pero responde `DOWN`
  (HTTP 503) de verdad si el promedio de ánimo/saciedad/energía de la
  mascota se queda muy bajo por más de unos segundos seguidos. No es un
  chequeo decorativo: la app se autoevalúa.

## Tasks

> Todos los comandos de este lab se corren desde
> `labs/lab04-health-probes`.

### 1. Agregar probes que funcionen

Completa los dos TODO en `manifests/deployment.yaml`: ambos probes
deben apuntar al puerto en el que realmente escucha este contenedor.
Aplícalo:

```bash
oc apply -f manifests/deployment.yaml
```

### 2. Confirmar que está sano

```bash
oc get pods -l app=podpet
oc describe pod -l app=podpet
```

En `oc describe pod`, busca las líneas `Readiness` y `Liveness` debajo
de la especificación del contenedor, y confirma que la sección Events
no muestra fallas de probe. `oc get pods` debería mostrar `1/1` en
`READY`.

### 3. Romper la readiness (error de configuración)

```bash
oc apply -f broken/deployment-bad-readiness.yaml
```

Observa qué pasa:

```bash
oc get pods -l app=podpet -w
```

Deberías ver que el Pod llega a `Running`, pero `READY` se queda en
`0/1` y nunca pasa a `1/1`. Esto es distinto de un crash: el proceso
está vivo, algo más está mal. Investiga usando:

```bash
oc describe pod -l app=podpet
oc get events --sort-by=.lastTimestamp
```

Responde:

- ¿Qué dice el `State` real del contenedor (Running, Waiting,
  Terminated)?
- ¿Qué dice el event Warning más reciente sobre el readiness probe, y
  qué puerto menciona?
- ¿Ese puerto coincide con el puerto en el que realmente escucha el
  contenedor (`containerPort` en el mismo manifiesto)?

### 4. Repararla

Corrige el readiness probe para que apunte al puerto correcto, y
reaplica `manifests/deployment.yaml`. Confirma que el Pod vuelve a
estar `1/1` Ready, y que `RESTARTS` **no** cambió: esto fue una falla
de readiness, no un crash.

### 5. Provocar una falla de liveness real

Ahora vas a romper algo distinto: no un typo de configuración, sino el
estado real de la aplicación. A través de la Route que ya existe desde
el Lab 3, descuida a la mascota:

```bash
HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl -X POST "http://${HOST}/api/pet/neglect"
```

Observa qué pasa en los próximos 20-30 segundos:

```bash
oc get pods -l app=podpet -w
```

Responde:

- ¿Cuánto tardó en aparecer el primer event `Unhealthy` de liveness?
- ¿Qué dice `oc describe pod` sobre la razón del reinicio (`Last
  State`, `Reason`, revisa también `oc logs <pod> --previous`)?
- ¿Subió `RESTARTS` esta vez? Compáralo con lo que pasó en el paso 3.

## Comandos útiles

```bash
oc apply -f <archivo>
oc get pods
oc describe pod <nombre>
oc get events --sort-by=.lastTimestamp
oc logs <pod> --previous
curl -X POST http://<host>/api/pet/neglect
```

## Validación

- Después del paso 1, `oc get pods -l app=podpet` muestra `1/1` Ready.
- Después del paso 3, muestra `0/1` Ready mientras `STATUS` sigue en
  `Running`, y `RESTARTS` no cambia.
- Después del paso 4, vuelve a mostrar `1/1` Ready.
- Después del paso 5, `RESTARTS` sube en uno, y el Pod vuelve solo a
  `1/1` Ready. Si consultas `/api/pet`, vas a ver que el contador
  `aliveSeconds` volvió a cero y las stats volvieron a sus valores
  iniciales: la mascota "nació de nuevo". El nombre se mantiene, porque
  viene de la variable de entorno `PET_NAME` (que el kubelet vuelve a
  inyectar en cada arranque), no de la memoria del proceso anterior.

## Limpieza

No hace falta antes del Lab 5, que usa nombres de aplicación distintos
en sus propios escenarios. Si después del paso 5 quieres volver a un
estado sano conocido (por ejemplo, si aplicaste la variante con la
readiness rota y no la reparaste), aplica la versión completa con los
probes correctos:

```bash
oc apply -f solution/deployment.yaml
```

Ese manifiesto define ambos probes en el puerto real (`8080`), así que
no depende de que hayas completado tu copia de `manifests/deployment.yaml`.
