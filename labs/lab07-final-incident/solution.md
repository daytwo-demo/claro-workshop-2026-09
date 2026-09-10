# Lab 7: Solución del Instructor

## La falla

`scenario/service.yaml` tiene el selector correcto (`app: payments-api`,
que sí coincide con las labels de los Pods), pero mapea el puerto del
Service al `targetPort` equivocado:

```yaml
ports:
  - name: http
    port: 8080
    targetPort: 8081   # el contenedor escucha en 8080
```

Por lo tanto el Service **sí tiene Endpoints** (aparecen las IPs de los
Pods, pero apuntando al puerto 8081), la Route está bien y los Pods
están `Running 1/1`. El tráfico llega hasta el Service y muere ahí: la
conexión a `pod:8081` se rechaza porque nadie escucha en ese puerto.

Este es, a propósito, un tipo de falla **distinto** al Escenario 3 del
Lab 5 (donde los Endpoints estaban vacíos por un selector mal puesto):
acá los Endpoints se ven poblados, así que el estudiante no puede
quedarse en esa capa y tiene que comparar los puertos.

## Proceso de razonamiento esperado

Un estudiante que llega en frío a "la aplicación de pagos no responde"
no debería saltar directo al Deployment. Guíalo (si se traba) por este
orden, que refleja la chuleta de troubleshooting:

1. **Reproducir**: hacer `curl` al hostname de la Route. Confirmar la
   falla (una página de error tipo *gateway* / 503, según el router);
   esto establece que el problema es aguas abajo de la Route.
2. **Route**: `oc get route payments-api` y `oc describe route
   payments-api`. La Route se ve bien: apunta al Service `payments-api`,
   puerto `http`. Callejón sin salida normal.
3. **Service**: `oc get svc payments-api` y, sobre todo,
   `oc get svc payments-api -o yaml` / `oc describe svc payments-api`.
   Acá está la pista: revisa `spec.ports[].port` contra
   `spec.ports[].targetPort`.
4. **Endpoints** (la trampa pedagógica): `oc get endpoints payments-api`
   **sí** muestra IPs de Pod, pero con el puerto equivocado (`:8081`).
   Una lista *vacía* es el Escenario 3 del Lab 5; una lista *poblada con
   el puerto equivocado* es este caso. La lección: "hay Endpoints" no
   alcanza para declarar sano el camino.
5. **Pods y contenedor**: `oc get pods -l app=payments-api` los muestra
   `Running 1/1`, y `oc get deploy payments-api -o jsonpath` (o el
   manifiesto) confirma `containerPort: 8080`. El desajuste está en el
   Service, no en los Pods.

## Causa raíz

El `spec.ports[0].targetPort` del Service `payments-api` apunta al
puerto `8081`, mientras el contenedor solo escucha en `8080`. El
selector está bien; el error es exclusivamente el mapeo de puertos.

## Arreglo

```bash
oc patch svc payments-api --type=json \
  -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
```

## Validación

```bash
oc get endpoints payments-api
# -> las IPs de Pod ahora en el puerto 8080

HOST=$(oc get route payments-api -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
# -> {"name":"payments-api","mood":80,"satiety":80,"energy":80,...}
```

## Notas de calificación para instructores

Un reporte completo debería:

- Nombrar específicamente el desajuste de `targetPort` del Service, no
  solo "el service estaba mal configurado".
- Mostrar evidencia de haber comparado el puerto real del contenedor
  (`containerPort: 8080`) con el `targetPort` del Service, no solo de
  haber leído el selector.
- Volver a probar vía la Route/`curl`, no solo vía `oc get endpoints`.

## Errores comunes

- Reiniciar o escalar el Deployment, o eliminar Pods, cuando nunca
  mostraron ningún problema: un buen momento para reforzar el punto del
  Lab 6 de que las acciones a nivel de Pod no arreglan problemas de
  Service.
- Cambiar el `spec.selector` del Service por prueba y error, aunque el
  selector ya era correcto. Señálalo: el síntoma (Endpoints poblados)
  descarta el selector y apunta a los puertos.
- "Arreglar" el desajuste cambiando el `containerPort` del Deployment a
  8081 en vez de corregir el Service: la app escucha en 8080, así que
  eso no la arregla.

## Reset

```bash
oc delete -f scenario/route.yaml -f scenario/service.yaml -f scenario/deployment.yaml --ignore-not-found
# después reaplica scenario/*.yaml para armar un incidente nuevo para otro intento
```
