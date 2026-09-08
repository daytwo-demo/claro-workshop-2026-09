# Lab 4: Health Probes

**Duración:** aproximadamente 30-35 minutos

## Objetivo

Agregar readiness y liveness probes al Deployment `hello-openshift`,
confirmar que funcionan, y después romper uno a propósito y
diagnosticar la falla de la misma forma en que lo harías en
producción: a partir de `oc get pods`, `oc describe pod` y events, no
leyendo el manifiesto primero.

## Escenario

Hasta ahora, OpenShift solo sabía si el proceso de tu contenedor estaba
corriendo. No tenía idea de si la aplicación de adentro realmente
podía atender tráfico. Los probes cierran esa brecha:

- Un **readiness probe** le dice a OpenShift si este Pod debería
  recibir tráfico a través de un Service en este momento. Un Pod puede
  estar `Running` y aun así estar `NotReady`.
- Un **liveness probe** le dice a OpenShift si el contenedor necesita
  reiniciarse porque quedó trabado.

## Tasks

### 1. Agregar probes que funcionen

Completa los dos TODO en `manifests/deployment.yaml`: ambos probes
deben apuntar al puerto en el que realmente escucha este contenedor.
Aplícalo:

```bash
oc apply -f manifests/deployment.yaml
```

### 2. Confirmar que está sano

```bash
oc get pods -l app=hello-openshift
oc describe pod -l app=hello-openshift
```

En `oc describe pod`, busca las líneas `Readiness` y `Liveness` debajo
de la especificación del contenedor, y confirma que la sección Events
no muestra fallas de probe. `oc get pods` debería mostrar `1/1` en
`READY`.

### 3. Romperlo

Aplica la variante rota:

```bash
oc apply -f broken/deployment-bad-readiness.yaml
```

### 4. Diagnosticar

Observa qué pasa:

```bash
oc get pods -l app=hello-openshift -w
```

Deberías ver que el Pod llega a `Running`, pero `READY` se queda en
`0/1` y nunca pasa a `1/1`. Esto es distinto de un crash: el proceso
está vivo, algo más está mal. Investiga usando:

```bash
oc describe pod -l app=hello-openshift
oc get events --sort-by=.lastTimestamp
```

Responde:

- ¿Qué dice el `State` real del contenedor (Running, Waiting,
  Terminated)?
- ¿Qué dice el event Warning más reciente sobre el readiness probe, y
  qué puerto menciona?
- ¿Ese puerto coincide con el puerto en el que realmente escucha el
  contenedor (`containerPort` en el mismo manifiesto)?

### 5. Repararlo

Corrige el readiness probe para que apunte al puerto correcto, y
reaplica. Confirma que el Pod vuelve a estar `1/1` Ready.

## Comandos útiles

```bash
oc apply -f <archivo>
oc get pods
oc describe pod <nombre>
oc get events --sort-by=.lastTimestamp
```

## Validación

- Después del paso 1, `oc get pods -l app=hello-openshift` muestra
  `1/1` Ready.
- Después del paso 3, muestra `0/1` Ready mientras `STATUS` sigue en
  `Running`.
- Después del paso 5, vuelve a mostrar `1/1` Ready, sin que el Pod se
  haya reiniciado en ningún momento (revisa `RESTARTS`: no debería
  haber subido, porque esto es una falla de readiness, no un crash).

## Limpieza

No hace falta antes del Lab 5, que usa nombres de aplicación distintos
en sus propios escenarios. Si quieres quitar los probes por ahora:

```bash
oc apply -f manifests/deployment.yaml
```
