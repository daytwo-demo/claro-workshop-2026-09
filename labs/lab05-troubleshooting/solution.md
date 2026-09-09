# Lab 5: Solución

## Escenario 1: `frontend` (ImagePullBackOff)

**SÍNTOMA:** `oc get pods -l app=frontend` nunca llega a `Running`.

**OBSERVACIÓN:**

```bash
oc get pods -l app=frontend
```
```
NAME                        READY   STATUS             RESTARTS   AGE
frontend-<hash>             0/1     ImagePullBackOff    0         2m
```

**EVIDENCIA:**

```bash
oc describe pod -l app=frontend
```
```
Warning  Failed     kubelet  Failed to pull image "ghcr.io/daytwo-demo/podpet:v9.9.9":
                     rpc error: ... not found
Warning  BackOff    kubelet  Back-off pulling image "ghcr.io/daytwo-demo/podpet:v9.9.9"
```

**CAUSA RAÍZ:** El Deployment referencia el tag `v9.9.9`, que no existe
para esta imagen.

**ARREGLO:** Edita la referencia de imagen del Deployment a
`ghcr.io/daytwo-demo/podpet:v1.0.1`:

```bash
oc set image deployment/frontend frontend=ghcr.io/daytwo-demo/podpet:v1.0.1
```

**VALIDACIÓN:**

```bash
oc rollout status deployment/frontend
oc get pods -l app=frontend
# -> Running, 1/1
```

---

## Escenario 2: `orders` (CrashLoopBackOff)

**SÍNTOMA:** `oc get pods -l app=orders` muestra un conteo de
`RESTARTS` que sigue subiendo.

**OBSERVACIÓN:**

```bash
oc get pods -l app=orders
```
```
NAME                      READY   STATUS             RESTARTS      AGE
orders-<hash>             0/1     CrashLoopBackOff   5 (30s ago)   4m
```

**EVIDENCIA:**

```bash
oc logs <pod> --previous
```
```
orders: fatal configuration error, exiting
```

```bash
oc describe pod -l app=orders
```
```
Last State:     Terminated
  Reason:       Error
  Exit Code:    1
```

**CAUSA RAÍZ:** El comando del contenedor sale a propósito con estado
`1` inmediatamente después de loguear un mensaje: no hay ningún
proceso de larga duración para que el kubelet lo mantenga vivo.

**ARREGLO:** Reemplaza el comando por uno que corra de forma continua
en vez de salir:

```yaml
command:
  - /bin/sh
  - -c
  - "echo 'orders: starting'; sleep infinity"
```

```bash
oc apply -f - <<'EOF'
# (aplicar acá el manifiesto de Deployment corregido)
EOF
```

**VALIDACIÓN:**

```bash
oc get pods -l app=orders
# -> Running, 1/1, RESTARTS se queda en 0 desde este punto en adelante
```

Nota para instructores: en un incidente real, "hacer que el proceso no
salga" casi nunca es el arreglo de verdad; el arreglo real es lo que
sea que el log de la aplicación esté señalando como error de
configuración. Este lab aísla la *mecánica* de diagnosticar un crash
loop (logs previos, exit code, conteo de reinicios); no pretende que
`orders` sea una aplicación real con un bug real que parchear.

---

## Escenario 3: `catalog` (Service sin endpoints)

**SÍNTOMA:** `curl` contra la Route de `catalog` falla o se cuelga,
aunque `oc get pods` muestra los Pods `Running`.

**OBSERVACIÓN:**

```bash
oc get route catalog
oc get svc catalog
oc get pods -l app=catalog
```

Los tres objetos existen y se ven bien a primera vista.

**EVIDENCIA:**

```bash
oc get endpoints catalog
```
```
NAME      ENDPOINTS   AGE
catalog   <none>      6m
```

```bash
oc get svc catalog -o jsonpath='{.spec.selector}{"\n"}'
# {"app":"catalog-backend"}

oc get pods -l app=catalog --show-labels
# las labels muestran app=catalog, NO app=catalog-backend
```

**CAUSA RAÍZ:** El `spec.selector` del Service (`app:
catalog-backend`) no coincide con la label que realmente tienen los
Pods (`app: catalog`), así que el Service no tiene backends.

**ARREGLO:**

```bash
oc patch svc catalog -p '{"spec":{"selector":{"app":"catalog"}}}'
```

**VALIDACIÓN:**

```bash
oc get endpoints catalog
# -> lista dos IPs de Pod en el puerto 8080

HOST=$(oc get route catalog -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
# -> {"name":"catalog","mood":80,"satiety":80,"energy":80,...}
```

---

## Escenario 4: `notifications` (Falla de readiness)

**SÍNTOMA:** `oc get pods -l app=notifications` muestra `Running` pero
`0/1` Ready, y se queda así.

**OBSERVACIÓN:**

```bash
oc get pods -l app=notifications
```
```
NAME                          READY   STATUS    RESTARTS   AGE
notifications-<hash>          0/1     Running   0          3m
```

**EVIDENCIA:**

```bash
oc describe pod -l app=notifications
```
```
Warning  Unhealthy  kubelet  Readiness probe failed: Get "http://10.x.x.x:8081/q/health/ready":
                     dial tcp 10.x.x.x:8081: connect: connection refused
```

**CAUSA RAÍZ:** El readiness probe apunta al puerto `8081`; el
contenedor solo escucha en `8080`.

**ARREGLO:**

```bash
oc patch deployment notifications --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8080}]'
```

**VALIDACIÓN:**

```bash
oc get pods -l app=notifications
# -> Running, 1/1
```

## Puntos de enseñanza en los cuatro escenarios

- Cada escenario tiene una huella distinta en `oc get pods`:
  `ImagePullBackOff` (nunca arrancó), `CrashLoopBackOff`
  (reiniciándose), `Running 0/1` con Endpoints vacío (problema de
  Service, el Pod en sí está bien), `Running 0/1` sin necesidad de
  revisar Endpoints (problema de probe, el Pod en sí está bien). Enseña
  a los estudiantes a leer las columnas `STATUS` y `READY` juntas, no
  por separado.
- El Escenario 3 es el más importante para tomarse con calma: no hay
  nada mal con el Pod. El bug vive completamente en el Service, algo
  fácil de pasar por alto si los estudiantes solo miran los Pods cuando
  algo está "caído".
- `frontend`, `catalog` y `notifications` corren la misma imagen
  (`podpet`), así que al arreglarlos van a ver la UI de la mascota. El
  Escenario 2 (`orders`) sigue usando una imagen UBI mínima a propósito:
  el punto ahí es la mecánica de un crash loop, no la aplicación en sí,
  y una imagen sin servidor HTTP hace ese punto más nítido.

## Reset

```bash
oc delete all -l lab=lab05
# después reaplica los cuatro manifiestos de escenario bajo scenarios/
# para restaurar el estado inicial para otro intento u otra cohorte
```
