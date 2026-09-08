# Lab 2: Desplegar una aplicación existente

**Duración:** aproximadamente 35-40 minutos

## Objetivo

Desplegar una imagen de contenedor ya construida en OpenShift usando un
Deployment, exponerla internamente con un Service, y exponerla
externamente con una Route. Después, observar cómo escalar un
Deployment afecta a sus Pods.

## Escenario

Tu equipo necesita correr una pequeña aplicación interna. Alguien más
ya construyó y publicó la imagen de contenedor; tu trabajo es
puramente operativo: tomar esa imagen existente y correrla
correctamente en el clúster. **No** vas a construir nada: sin
Dockerfile, sin BuildConfig, sin S2I. La imagen ya existe en:

```
docker.io/openshift/hello-openshift:v3.9.0
```

Esta imagen escucha en el puerto 8080 y devuelve una respuesta HTTP
simple. Lee su texto de respuesta desde la variable de entorno
`RESPONSE`.

## Tasks

### 1. Desplegar

Abre `manifests/deployment.yaml`. Tiene dos espacios en blanco para que
completes:

- El `image` del contenedor.
- La variable de entorno `RESPONSE`, que debe quedar en:
  `Hello from OpenShift Operations Workshop`

Completa ambos, y crea el Deployment:

```bash
oc apply -f manifests/deployment.yaml
```

### 2. Exponer internamente

Revisa `manifests/service.yaml`. Nota cómo `spec.selector` se relaciona
con las `labels` del Pod template en el Deployment que acabas de crear:
ese es el mecanismo que conecta un Service con un conjunto de Pods.
Aplícalo:

```bash
oc apply -f manifests/service.yaml
```

### 3. Exponer externamente

Revisa `manifests/route.yaml`, y aplícalo:

```bash
oc apply -f manifests/route.yaml
```

### 4. Verificar

Revisa cada capa:

```bash
oc get deployment hello-openshift
oc get pods -l app=hello-openshift
oc get svc hello-openshift
oc get endpoints hello-openshift
oc get route hello-openshift
```

Confirma que el objeto Endpoints realmente lista una IP y puerto de
Pod: una lista de Endpoints vacía significa que el Service no está
llegando a ningún Pod, aunque el objeto Service exista.

Obtén el hostname de la Route y accede a ella:

```bash
oc get route hello-openshift -o jsonpath='{.spec.host}'
curl http://<el-hostname-de-arriba>
```

Deberías ver el texto de respuesta que configuraste en el paso 1.
También puedes abrir el hostname en un navegador.

### 5. Escalar

Escala el Deployment de 1 réplica a 3, y después de vuelta a 1:

```bash
oc scale deployment/hello-openshift --replicas=3
oc get pods -l app=hello-openshift -w
```

Observa aparecer los Pods nuevos. Cuando todos estén `Running` y `1/1`
Ready, revisa el ReplicaSet y Endpoints:

```bash
oc get replicaset -l app=hello-openshift
oc get endpoints hello-openshift
```

Después escala de vuelta:

```bash
oc scale deployment/hello-openshift --replicas=1
oc get pods -l app=hello-openshift
```

Fíjate en qué Pods sobreviven y cuáles se terminan: escalar hacia abajo
no necesariamente conserva el Pod más "viejo".

## Comandos útiles

```bash
oc apply -f <archivo>
oc get deployment
oc get pods
oc get svc
oc get endpoints
oc get route
oc get replicaset
oc scale deployment/<nombre> --replicas=<n>
oc logs <pod>
```

## Validación

- `oc get route hello-openshift` muestra un hostname, y `curl` contra
  él devuelve exactamente el texto que configuraste.
- `oc get endpoints hello-openshift` nunca muestra una lista de
  endpoints vacía mientras al menos un Pod esté Running y Ready.
- Después de escalar a 3 y volver a 1, queda exactamente un Pod, y está
  `Running`/`1/1`.

## Limpieza

No hace falta antes del Lab 3: el Lab 3 construye directamente sobre
este Deployment. Si de todas formas quieres eliminarlo:

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml
```
