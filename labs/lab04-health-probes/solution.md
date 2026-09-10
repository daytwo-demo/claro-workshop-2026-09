# Lab 4: Solución

## Bloque de probes completo

```yaml
          readinessProbe:
            httpGet:
              path: /q/health/ready
              port: 8080
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /q/health/live
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 2
```

## Comandos

```bash
oc apply -f manifests/deployment.yaml
oc get pods -l app=podpet
oc describe pod -l app=podpet

# romper readiness
oc apply -f broken/deployment-bad-readiness.yaml
oc get pods -l app=podpet -w
oc describe pod -l app=podpet
oc get events --sort-by=.lastTimestamp

# reparar
oc apply -f manifests/deployment.yaml
oc get pods -l app=podpet

# falla de liveness real
HOST=$(oc get route podpet -o jsonpath='{.spec.host}')
curl -X POST "http://${HOST}/api/pet/neglect"
oc get pods -l app=podpet -w
oc describe pod -l app=podpet
oc logs -l app=podpet --previous
```

## Salida esperada: readiness rota

```
Warning  Unhealthy  <edad> (x3 over <edad>)  kubelet  Readiness probe failed:
Get "http://10.x.x.x:8081/q/health/ready": dial tcp 10.x.x.x:8081: connect: connection refused
```

```
NAME                    READY   STATUS    RESTARTS   AGE
podpet-<hash>           0/1     Running   0          1m
```

`RESTARTS` se queda en `0`: el contenedor está bien, el probe está mal
configurado.

## Salida esperada: liveness real

Unos segundos después de `curl .../api/pet/neglect`:

```
Warning  Unhealthy  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 503
Normal   Killing    kubelet  Container podpet failed liveness probe, will be restarted
```

```
NAME                    READY   STATUS    RESTARTS      AGE
podpet-<hash>           1/1     Running   1 (5s ago)    4m
```

Esta vez `RESTARTS` sí sube: el contenedor no estaba "trabado", pero
la aplicación misma reportó no estar bien, y Kubernetes actuó en
consecuencia.

## Puntos de enseñanza

- `READY 0/1` + `STATUS Running` + `RESTARTS 0` es un patrón específico
  y reconocible de "probe mal configurado", distinto de una falla de
  liveness real, donde `RESTARTS` sí sube.
- La diferencia clave entre los pasos 3 y 5 de este lab: en el paso 3
  el *cluster* está mal configurado (probe apuntando al puerto
  equivocado); en el paso 5 la *aplicación* reporta genuinamente no
  estar bien. Ambos se ven parecidos en `oc describe pod` (eventos
  `Unhealthy`), pero solo el segundo dispara un restart.
- El endpoint `/api/pet/neglect` existe solo para hacer este ejercicio
  reproducible en minutos en vez de esperar el decaimiento natural (que
  tardaría varios minutos en llegar a un promedio crítico). Vale la
  pena que los estudiantes entiendan que en una aplicación real, el
  liveness check reflejaría alguna condición de negocio genuina (una
  cola de trabajo trabada, una conexión a base de datos perdida, etc.),
  no un botón de demo.

## Errores comunes

- Confundir el paso 3 con un problema de imagen o de crash y revisar
  primero `oc logs`, cuando la señal más rápida en el caso de
  readiness está en los events `Unhealthy` de `oc describe pod`.
- En el paso 5, esperar ver el Pod "caído" permanentemente: PodPet se
  recupera solo, porque el reinicio del contenedor reinicia también sus
  stats a valores sanos (80/80/80). Si el Pod vuelve a caer en
  `neglect` inmediatamente después de nacer, algo más está mal (por
  ejemplo, `failureThreshold`/`periodSeconds` demasiado agresivos).

## Reset

```bash
oc apply -f solution/deployment.yaml
```
