# Lab 4: Solución

## Bloque de probes completo

```yaml
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
```

## Comandos

```bash
oc apply -f manifests/deployment.yaml
oc get pods -l app=hello-openshift
oc describe pod -l app=hello-openshift

oc apply -f broken/deployment-bad-readiness.yaml
oc get pods -l app=hello-openshift -w
oc describe pod -l app=hello-openshift
oc get events --sort-by=.lastTimestamp

# arreglo: reaplicar el manifiesto que funciona
oc apply -f manifests/deployment.yaml
oc get pods -l app=hello-openshift
```

## Salida esperada

Después de aplicar el manifiesto roto, `oc describe pod` muestra un
event parecido a:

```
Warning  Unhealthy  <edad> (x3 over <edad>)  kubelet  Readiness probe failed:
Get "http://10.x.x.x:8081/": dial tcp 10.x.x.x:8081: connect: connection refused
```

`oc get pods` muestra:

```
NAME                                READY   STATUS    RESTARTS   AGE
hello-openshift-<hash>              0/1     Running   0          1m
```

`RESTARTS` se queda en `0`: esta es la señal clave que distingue una
falla de readiness de un crash. El contenedor está bien; el probe está
mal configurado.

## Puntos de enseñanza

- `READY 0/1` + `STATUS Running` + `RESTARTS 0` es un patrón específico
  y reconocible de "probe mal configurado", distinto de
  `CrashLoopBackOff` (que se cubre en el Lab 5).
- Un readiness probe que falla saca al Pod de los Endpoints del Service
  de inmediato: conecta esto con las verificaciones de Endpoints del
  Lab 2/3.
- Un liveness probe que falla, en cambio, hace que el kubelet reinicie
  el contenedor, lo que **sí** aumentaría `RESTARTS`. Señala esta
  diferencia explícitamente, ya que ambos probes usan `httpGet` y se
  ven parecidos en el manifiesto, pero se comportan muy distinto
  cuando fallan.

## Errores comunes

- Confundir esto con un problema de imagen o de crash y revisar
  primero `oc logs`, cuando la señal más rápida en realidad está en
  los events `Unhealthy` de `oc describe pod`.
- Arreglar el puerto pero no cuestionar el `path: /` en ningún momento:
  para este ejercicio el path ya está bien, pero en general los
  estudiantes deberían verificar ambos por separado, en vez de asumir
  que el path está bien solo porque el puerto era lo que estaba mal.

## Reset

```bash
oc apply -f manifests/deployment.yaml
```
