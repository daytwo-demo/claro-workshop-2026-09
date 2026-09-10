# Chuleta de troubleshooting: "la aplicación no responde"

Imprime esto. Trabaja de arriba hacia abajo; no te saltes una capa solo
porque "parece" estar bien: confírmala con un comando, no con una
suposición.

```
 1. Route         ¿La Route existe y apunta al Service/puerto correctos?
        │
 2. Service       ¿El Service existe? ¿El mapeo port -> targetPort es correcto?
        │
 3. Endpoints     ¿El Service realmente tiene IPs de backend?
        │
 4. Pods          ¿Están corriendo los Pods correctos, y cuántos?
        │
 5. Contenedor    ¿El estado del contenedor es Running, Waiting o Terminated?
        │
 6. Readiness     ¿El contenedor está Running pero NO Ready?
        │
 7. Logs          ¿Qué dice la aplicación en sí?
        │
 8. Events        ¿Qué observó el clúster recientemente sobre este objeto?
        │
 9. Rollout       ¿Cambió algo hace poco (nueva revisión, un edit malo)?
```

## 1. Route

```bash
oc get routes
oc describe route <nombre>
```

Revisa: ¿`spec.to.name` coincide con un Service real? ¿`spec.port.targetPort`
coincide con un puerto que el Service realmente expone?

## 2. Service

```bash
oc get svc
oc describe svc <nombre>
```

Revisa: `spec.selector`, ¿coincide con las labels de los Pods a los que
esperas que enrute? Revisa `spec.ports[].port` y `.targetPort`.

## 3. Endpoints / EndpointSlices

```bash
oc get endpoints <nombre>
oc get endpointslices -l kubernetes.io/service-name=<nombre>
```

Una columna `ENDPOINTS` vacía (o ninguna dirección en el slice)
significa que el selector del Service no coincide con ningún Pod
Ready. Esta es una de las causas más comunes de "la aplicación está
caída" cuando los Pods se ven bien.

Ojo: **Endpoints poblados no garantizan que el camino funcione**. Si
los Endpoints existen pero muestran el puerto equivocado, el selector
está bien pero el `targetPort` del Service no: el tráfico llega al Pod
y la conexión se rechaza. En ese caso el problema está en
`spec.ports[].targetPort`, no en el selector.

## 4. Pods

```bash
oc get pods
oc get pods -o wide
oc get pods --show-labels
```

Revisa: cantidad de Pods, columna `READY` (`1/1` vs `0/1`), `STATUS`,
conteo de reinicios, y en qué nodo cayó cada uno.

## 5. Estado del contenedor

```bash
oc describe pod <nombre>
```

Mira `State`/`Last State` de cada contenedor: `Running`, `Waiting` (con
un `Reason` como `ImagePullBackOff` o `CrashLoopBackOff`), o
`Terminated` (con un `Exit Code` y `Reason`).

## 6. Readiness

`READY` mostrando `0/1` mientras `STATUS` muestra `Running` significa
que el proceso del contenedor arrancó, pero el readiness probe está
fallando: el kubelet no va a marcar el Pod como Ready, y el Service no
lo va a agregar a Endpoints. Esto es distinto de un crash. Revisa las
fallas del probe en Events.

## 7. Logs

```bash
oc logs <pod>
oc logs <pod> -c <contenedor>          # pods multi-contenedor
oc logs <pod> --previous              # la instancia que crasheó, no la nueva
oc logs <pod> --previous -f
```

## 8. Events

```bash
oc get events --sort-by=.lastTimestamp
oc describe pod <nombre>              # incluye los events recientes del propio pod
```

Los events expiran después de aproximadamente una hora por defecto. Si
estás investigando algo que pasó antes, los logs y la salida de
`describe` son evidencia más duradera.

## 9. Rollout / cambio reciente

```bash
oc rollout status deployment/<nombre>
oc rollout history deployment/<nombre>
oc get deployment <nombre> -o yaml
```

Pregunta: ¿alguien cambió un tag de imagen, una env var, un probe o un
selector hace poco? Un rollout de Deployment que nunca completa es una
señal fuerte de que la revisión más nueva está rota; revisa si la
revisión anterior estaba bien antes de recurrir a `rollout undo`.

## Referencia rápida

| Comando | Qué te dice |
|---|---|
| `oc get pods` | Conteo, estado, reinicios |
| `oc get pods -o wide` | + nodo, IP del pod |
| `oc describe pod <nombre>` | Estado completo, probes, events |
| `oc logs <pod>` | Salida stdout/stderr del contenedor actual |
| `oc logs <pod> --previous` | Salida del último contenedor que crasheó |
| `oc get events --sort-by=.lastTimestamp` | Events recientes observados por el clúster |
| `oc get svc` | Puertos y selector del Service |
| `oc get deploy <nombre> -o yaml` | Puerto real del contenedor (`containerPort`) para comparar contra el `targetPort` del Service |
| `oc get endpoints` | IPs de backend reales detrás de un Service |
| `oc get endpointslices` | Lo mismo, en la API más nueva |
| `oc get routes` | Hostnames externos y service/puerto de destino |
| `oc describe route <nombre>` | Mapeo completo de route a service |
| `oc rollout status deployment/<nombre>` | ¿El rollout actual está completo? |
| `oc rollout history deployment/<nombre>` | Revisiones pasadas |

## Tres cosas que reiniciar un Pod nunca arregla

- Un **selector de Service** mal configurado: los Pods están bien, el
  Service apunta a la label equivocada.
- Un **puerto (`targetPort`) de Service** mal configurado: el selector
  está bien y hasta hay Endpoints, pero apuntan al puerto equivocado.
- Una **configuración de Deployment** mal hecha (tag de imagen
  incorrecto, path de probe incorrecto): reiniciar un Pod solo recrea
  la misma configuración rota.

Si no estás seguro de qué capa está rota, empieza arriba de esta
chuleta y ve bajando. No adivines: confirma cada capa con el comando
correspondiente.
