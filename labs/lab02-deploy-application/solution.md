# Lab 2: Solución

## `manifests/deployment.yaml` completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-openshift
  labels:
    app: hello-openshift
    lab: lab02
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-openshift
  template:
    metadata:
      labels:
        app: hello-openshift
        lab: lab02
    spec:
      containers:
        - name: hello-openshift
          image: docker.io/openshift/hello-openshift:v3.9.0
          ports:
            - containerPort: 8080
          env:
            - name: RESPONSE
              value: "Hello from OpenShift Operations Workshop"
```

## Comandos

```bash
oc apply -f manifests/deployment.yaml
oc apply -f manifests/service.yaml
oc apply -f manifests/route.yaml

oc get deployment hello-openshift
oc get pods -l app=hello-openshift
oc get svc hello-openshift
oc get endpoints hello-openshift
oc get route hello-openshift

HOST=$(oc get route hello-openshift -o jsonpath='{.spec.host}')
curl "http://${HOST}"
# -> Hello from OpenShift Operations Workshop

oc scale deployment/hello-openshift --replicas=3
oc get pods -l app=hello-openshift
oc scale deployment/hello-openshift --replicas=1
oc get pods -l app=hello-openshift
```

## Puntos de enseñanza

- El `spec.selector` del Service (`app: hello-openshift`) debe coincidir
  con las labels del **Pod template** del Deployment, no con
  `metadata.labels` del propio Deployment. Este es el punto de
  confusión más común de todo el lab, y es exactamente el mecanismo
  que el Escenario 3 del Lab 5 rompe a propósito.
- El `spec.port.targetPort: http` de la Route se refiere al **puerto
  con nombre** del Service, no directamente al puerto del contenedor.
  Señala que el Service es la capa de indirección entre la Route y el
  Pod.
- Escalar a 3 y volver a 1 no necesariamente conserva el primer Pod que
  se creó: el controller del Deployment puede terminar cualquiera de
  los tres. Es un buen momento para reforzar que los Pods son
  descartables y que nunca se debe asumir identidad a nivel de Pod.

## Errores comunes

- Dejar `image: ""` sin completar y obtener `ErrImageNeverPull` o un
  error de validación, sin leer el mensaje de error real.
- Escribir mal el valor de `RESPONSE` y no notarlo hasta que `curl`
  devuelve algo inesperado: buen momento para señalar `oc logs` y
  `oc get pods -o yaml` para confirmar qué valor de env var recibió
  realmente el contenedor.
- Olvidar `-l app=hello-openshift` y confundir los Pods de este
  Deployment con `sample-inventory` del Lab 1, que sigue corriendo en
  el mismo project.

## Reset

```bash
oc delete -f manifests/route.yaml -f manifests/service.yaml -f manifests/deployment.yaml --ignore-not-found
```
