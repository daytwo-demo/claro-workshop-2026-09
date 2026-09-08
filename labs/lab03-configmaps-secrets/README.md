# Lab 3: ConfigMaps y Secrets

**Duración:** aproximadamente 30 minutos

## Objetivo

Sacar la configuración del Deployment y moverla a un ConfigMap,
observar el rollout que resulta de cambiarla, e inyectar un Secret en
el mismo Pod. Entender qué hace, y qué no hace, OpenShift para
proteger los datos de un Secret.

## Escenario

Partes de la aplicación `hello-openshift` que desplegaste en el Lab 2.
Tener `RESPONSE` hardcodeado directamente en el Deployment significa
que cambiarlo requiere editar y reaplicar el Deployment completo. En
vez de eso, vas a mover ese valor a un ConfigMap, para que la
configuración y la definición del workload queden separadas. Después
vas a agregar un Secret con dos credenciales ficticias, únicamente para
practicar cómo se crean, se montan y se inspeccionan los Secrets: esto
es **solo datos de entrenamiento**, no un patrón para manejar
credenciales reales de esta forma sin un endurecimiento adicional.

## Tasks

### 1. Crear el ConfigMap

Completa el TODO en `manifests/configmap.yaml` (define `RESPONSE` como
`Hello from a ConfigMap`), y aplícalo:

```bash
oc apply -f manifests/configmap.yaml
oc get configmap hello-openshift-config -o yaml
```

### 2. Crear el Secret

Completa los dos TODO en `manifests/secret.yaml`:

- `username`: `workshop`
- `password`: `openshift123`

```bash
oc apply -f manifests/secret.yaml
```

Inspecciónalo sin decodificar los valores todavía:

```bash
oc get secret hello-openshift-credentials
oc describe secret hello-openshift-credentials
```

Nota que `oc describe` muestra las **keys** (`username`, `password`) y
su tamaño en bytes, pero no los valores. Ahora mira el objeto crudo:

```bash
oc get secret hello-openshift-credentials -o yaml
```

Los valores están codificados en base64, no encriptados. Decodifica
uno para confirmarlo:

```bash
oc get secret hello-openshift-credentials -o jsonpath='{.data.username}' | base64 -d
```

Cualquiera que pueda hacer `oc get secret -o yaml` sobre este objeto
puede recuperar el texto plano sin esfuerzo. Base64 es una codificación
para transporte dentro de JSON/YAML, no un control de seguridad: las
credenciales reales de producción necesitan encriptación de Secrets en
reposo, RBAC estricto sobre `get`/`list` de secrets, y muchas veces un
gestor de secrets externo. Nada de eso se enseña acá, y nada reemplaza
mantener los valores fuera de un repositorio de workshop como este, que
es justamente por qué este Secret solo contiene valores ficticios.

### 3. Referenciar ambos desde el Deployment

Completa los TODO en `manifests/deployment.yaml` para que:

- `RESPONSE` venga del ConfigMap que creaste.
- `SECRET_USERNAME` y `SECRET_PASSWORD` vengan del Secret que creaste.

Aplícalo:

```bash
oc apply -f manifests/deployment.yaml
```

### 4. Observar el rollout

```bash
oc rollout status deployment/hello-openshift
oc get pods -l app=hello-openshift
```

Se crea un Pod nuevo porque el Pod template cambió (el bloque `env` es
distinto al del Lab 2), aunque la imagen del contenedor en sí no
cambió.

### 5. Verificar

Confirma que la respuesta HTTP de la aplicación ahora refleja el valor
del ConfigMap:

```bash
HOST=$(oc get route hello-openshift -o jsonpath='{.spec.host}')
curl "http://${HOST}"
```

Confirma que los valores del Secret realmente llegaron al entorno del
contenedor (la aplicación en sí no usa estas dos variables, así que
revisa el entorno del contenedor directamente, no la respuesta HTTP):

```bash
oc exec deploy/hello-openshift -- printenv SECRET_USERNAME SECRET_PASSWORD
```

## Comandos útiles

```bash
oc apply -f <archivo>
oc get configmap
oc get secret
oc describe secret <nombre>
oc get secret <nombre> -o jsonpath='{.data.<key>}' | base64 -d
oc rollout status deployment/<nombre>
oc exec deploy/<nombre> -- printenv <VAR>
```

## Validación

- `curl` contra la Route devuelve `Hello from a ConfigMap`.
- `oc exec` dentro del Pod muestra `SECRET_USERNAME=workshop` y
  `SECRET_PASSWORD=openshift123` en el entorno.
- Puedes explicar, en una frase, por qué base64 no es encriptación.

## Limpieza

No hace falta antes del Lab 4: el Lab 4 continúa desde este Deployment.
Para eliminar todo lo de este lab en particular:

```bash
oc delete -f manifests/deployment.yaml -f manifests/secret.yaml -f manifests/configmap.yaml
```
