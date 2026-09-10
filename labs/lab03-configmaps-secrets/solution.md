# Lab 3: Solución

## ConfigMap completo

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podpet-config
  labels:
    app: podpet
    lab: lab03
data:
  PET_NAME: "Configstein"
```

## Secret completo

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podpet-credentials
  labels:
    app: podpet
    lab: lab03
type: Opaque
stringData:
  username: "workshop"
  password: "openshift123"
```

## Bloque `env` del Deployment completo

```yaml
          env:
            - name: PET_NAME
              valueFrom:
                configMapKeyRef:
                  name: podpet-config
                  key: PET_NAME
            - name: SECRET_USERNAME
              valueFrom:
                secretKeyRef:
                  name: podpet-credentials
                  key: username
            - name: SECRET_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: podpet-credentials
                  key: password
```

## Comandos

```bash
oc apply -f manifests/configmap.yaml
oc apply -f manifests/secret.yaml
oc apply -f manifests/deployment.yaml
oc apply -f manifests/service.yaml
oc apply -f manifests/route.yaml

oc rollout status deployment/podpet
oc get pods -l app=podpet

HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
# -> {"name":"Configstein","mood":80,"satiety":80,"energy":80,"aliveSeconds":...,"status":"feliz"}

oc exec deploy/podpet -- printenv SECRET_USERNAME SECRET_PASSWORD

# paso 6: cambiar el ConfigMap y reconciliar
oc patch configmap podpet-config --type merge -p '{"data":{"PET_NAME":"Mudanza"}}'
oc rollout status deployment/podpet        # no hay rollout nuevo
oc get pods -l app=podpet                  # los Pods no cambian
curl "http://${HOST}/api/pet"              # sigue el nombre viejo
oc rollout restart deployment/podpet
oc rollout status deployment/podpet
curl "http://${HOST}/api/pet"              # ahora sí, "Mudanza"
```

## Puntos de enseñanza

- Editar un ConfigMap in place **no** dispara, por sí solo, un rollout
  nuevo para los Pods que lo referencian vía `configMapKeyRef`: la
  variable de entorno solo se lee al arrancar el contenedor. El paso 6
  del lab lo demuestra en vivo: cambiar el ConfigMap deja la API
  devolviendo el valor viejo hasta que se reemplazan los Pods con
  `oc rollout restart`. Un Deployment nuevo (como el que se aplica en
  los pasos 1-3) sí dispara un rollout porque cambia el Pod template.
- La codificación base64 de los datos de un Secret es para transporte
  seguro dentro de un documento JSON/YAML, no confidencialidad.
  `oc get secret -o yaml` más `base64 -d` es todo lo que hace falta
  para leer el contenido de un Secret: cualquiera con acceso `get`
  sobre Secrets en el namespace puede hacerlo. El manejo real de
  credenciales necesita encriptación de etcd en reposo, RBAC que
  restrinja quién puede hacer `get`/`list` sobre secrets, y muchas
  veces un gestor de secrets externo; nada de eso se enseña acá, y nada
  de eso es razón para poner credenciales reales en este Secret.
- Este lab introduce una aplicación nueva (`podpet`), no una
  continuación de `hello-openshift`: por eso hace falta crear Service y
  Route nuevos, algo que en el diseño anterior del workshop no era
  necesario en este punto. Vale la pena señalarlo explícitamente para
  que nadie pierda tiempo buscando un Service `hello-openshift` que ya
  no aplica.

## Errores comunes

- Dejar `name: ""` sin completar en alguno de los tres bloques
  `valueFrom`: el Deployment se aplica sin problema, pero el Pod falla
  al arrancar con un error claro visible en `oc describe pod`
  (`configmap ... not found` o `secret ... not found`).
- Intentar hacer `curl` a `/` en vez de `/api/pet` y no ver el nombre
  configurado como texto plano: la UI en `/` sí lo muestra, pero
  renderizado dentro del HTML, no como texto plano fácil de `grep`. Para
  verificar rápido desde la terminal, `/api/pet` es más directo.
- Intentar ver `SECRET_USERNAME`/`SECRET_PASSWORD` en la respuesta de
  la API: PodPet no usa esas variables para nada, hay que revisarlas
  directamente en el entorno del contenedor.

## Reset

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml -f manifests/secret.yaml -f manifests/configmap.yaml --ignore-not-found
```
