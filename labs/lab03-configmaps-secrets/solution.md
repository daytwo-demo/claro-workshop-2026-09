# Lab 3: Solución

## ConfigMap completo

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: hello-openshift-config
  labels:
    app: hello-openshift
    lab: lab03
data:
  RESPONSE: "Hello from a ConfigMap"
```

## Secret completo

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hello-openshift-credentials
  labels:
    app: hello-openshift
    lab: lab03
type: Opaque
stringData:
  username: "workshop"
  password: "openshift123"
```

## Bloque `env` del Deployment completo

```yaml
          env:
            - name: RESPONSE
              valueFrom:
                configMapKeyRef:
                  name: hello-openshift-config
                  key: RESPONSE
            - name: SECRET_USERNAME
              valueFrom:
                secretKeyRef:
                  name: hello-openshift-credentials
                  key: username
            - name: SECRET_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: hello-openshift-credentials
                  key: password
```

## Comandos

```bash
oc apply -f manifests/configmap.yaml
oc apply -f manifests/secret.yaml
oc apply -f manifests/deployment.yaml

oc rollout status deployment/hello-openshift
oc get pods -l app=hello-openshift

HOST=$(oc get route hello-openshift -o jsonpath='{.spec.host}')
curl "http://${HOST}"
# -> Hello from a ConfigMap

oc exec deploy/hello-openshift -- printenv SECRET_USERNAME SECRET_PASSWORD
```

## Puntos de enseñanza

- Editar un ConfigMap in place **no** dispara, por sí solo, un rollout
  nuevo para los Pods que lo referencian vía `configMapKeyRef`: la
  variable de entorno solo se lee al arrancar el contenedor. Lo que
  dispara el rollout acá es que **el Pod template del Deployment
  cambió** (todo el bloque `env` es distinto al del Lab 2). Asegúrate
  de que los estudiantes vean la diferencia: si solo hubieran editado
  el ConfigMap sin reaplicar el Deployment, los Pods existentes
  conservarían el valor viejo hasta que se reinicien.
- La codificación base64 de los datos de un Secret es para transporte
  seguro dentro de un documento JSON/YAML, no confidencialidad.
  `oc get secret -o yaml` más `base64 -d` es todo lo que hace falta
  para leer el contenido de un Secret: cualquiera con acceso `get`
  sobre Secrets en el namespace puede hacerlo. El manejo real de
  credenciales necesita encriptación de etcd en reposo, RBAC que
  restrinja quién puede hacer `get`/`list` sobre secrets, y muchas
  veces un gestor de secrets externo; nada de eso se enseña acá, y nada
  de eso es razón para poner credenciales reales en este Secret.

## Errores comunes

- Dejar `name: ""` sin completar en alguno de los tres bloques
  `valueFrom`: el Deployment se aplica sin problema, pero el Pod falla
  al arrancar con un error claro visible en `oc describe pod`
  (`configmap ... not found` o `secret ... not found`). Úsalo como
  puente natural hacia el énfasis del Lab 4/5 en leer los events del
  Pod.
- Intentar hacer `curl` y esperar ver `SECRET_USERNAME`/
  `SECRET_PASSWORD` en la respuesta HTTP: la imagen `hello-openshift`
  solo refleja `RESPONSE`. Las otras dos variables hay que revisarlas
  directamente en el entorno del contenedor.

## Reset

```bash
oc delete -f manifests/deployment.yaml -f manifests/secret.yaml -f manifests/configmap.yaml --ignore-not-found
```
