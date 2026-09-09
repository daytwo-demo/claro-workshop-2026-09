# Lab 3: ConfigMaps y Secrets

**Duración:** aproximadamente 30 minutos

## Objetivo

Externalizar configuración a un ConfigMap y observar el rollout que
resulta de cambiarla; crear un Secret, inspeccionar sus metadata, y
entender que base64 es codificación, no encriptación.

## Escenario

Hasta ahora trabajaste con `hello-openshift`, deliberadamente mínima,
para aprender la mecánica de Deployment/Service/Route sin distracciones.
A partir de este lab, y para el resto del workshop, vas a trabajar con
**PodPet**: una mascota virtual (Java/Quarkus, sin base de datos) un
poco más real, con su propia UI y su propia API. Es, igual que
`hello-openshift`, una imagen ya construida y publicada: no vas a
compilar nada.

PodPet lee el nombre de la mascota desde la variable de entorno
`PET_NAME`. En vez de hardcodearlo en el Deployment, lo vas a mover a
un ConfigMap. Después vas a agregar un Secret con dos credenciales
ficticias, únicamente para practicar cómo se crean, se montan y se
inspeccionan los Secrets: esto es **solo datos de entrenamiento**, no
un patrón para manejar credenciales reales de esta forma sin un
endurecimiento adicional.

## Tasks

### 1. Crear el ConfigMap

Completa el TODO en `manifests/configmap.yaml` (elige un nombre para
la mascota, por ejemplo `Configstein`), y aplícalo:

```bash
oc apply -f manifests/configmap.yaml
oc get configmap podpet-config -o yaml
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
oc get secret podpet-credentials
oc describe secret podpet-credentials
```

Nota que `oc describe` muestra las **keys** (`username`, `password`) y
su tamaño en bytes, pero no los valores. Ahora mira el objeto crudo:

```bash
oc get secret podpet-credentials -o yaml
```

Los valores están codificados en base64, no encriptados. Decodifica
uno para confirmarlo:

```bash
oc get secret podpet-credentials -o jsonpath='{.data.username}' | base64 -d
```

Cualquiera que pueda hacer `oc get secret -o yaml` sobre este objeto
puede recuperar el texto plano sin esfuerzo. Base64 es una codificación
para transporte dentro de JSON/YAML, no un control de seguridad: las
credenciales reales de producción necesitan encriptación de Secrets en
reposo, RBAC estricto sobre `get`/`list` de secrets, y muchas veces un
gestor de secrets externo. Nada de eso se enseña acá, y nada reemplaza
mantener los valores fuera de un repositorio de workshop como este, que
es justamente por qué este Secret solo contiene valores ficticios.

### 3. Desplegar PodPet referenciando ambos

Completa los TODO en `manifests/deployment.yaml` para que:

- `PET_NAME` venga del ConfigMap que creaste.
- `SECRET_USERNAME` y `SECRET_PASSWORD` vengan del Secret que creaste.

Aplícalo, junto con el Service y la Route (nuevos: `podpet` es una
aplicación distinta de `hello-openshift`, no una continuación):

```bash
oc apply -f manifests/deployment.yaml
oc apply -f manifests/service.yaml
oc apply -f manifests/route.yaml
```

### 4. Observar el rollout

```bash
oc rollout status deployment/podpet
oc get pods -l app=podpet
```

### 5. Verificar

Confirma que la mascota tiene el nombre que configuraste:

```bash
HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
```

Deberías ver `"name":"Configstein"` (o el nombre que hayas elegido) en
la respuesta JSON. También puedes abrir `http://<HOST>` en un navegador
para ver la UI de la mascota.

Confirma que los valores del Secret realmente llegaron al entorno del
contenedor (PodPet no usa estas dos variables para nada, así que revisa
el entorno del contenedor directamente, no la respuesta de la API):

```bash
oc exec deploy/podpet -- printenv SECRET_USERNAME SECRET_PASSWORD
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

- `curl .../api/pet` devuelve `"name"` con el valor que configuraste en
  el ConfigMap.
- `oc exec` dentro del Pod muestra `SECRET_USERNAME=workshop` y
  `SECRET_PASSWORD=openshift123` en el entorno.
- Puedes explicar, en una frase, por qué base64 no es encriptación.

## Limpieza

No hace falta antes del Lab 4: el Lab 4 continúa desde este Deployment.
Para eliminar todo lo de este lab en particular:

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml -f manifests/secret.yaml -f manifests/configmap.yaml
```
