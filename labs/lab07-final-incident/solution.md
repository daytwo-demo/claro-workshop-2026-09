# Lab 7: Solución del Instructor

## La falla

`scenario/service.yaml` le da al Service `payments-api` un selector de
`app: payments-processor`. Los Pods reales, creados por
`scenario/deployment.yaml`, tienen la label `app: payments-api`. Por
lo tanto, el Service tiene cero endpoints, aunque el Deployment, sus
Pods, el objeto Service y el objeto Route existen todos y se ven bien
por separado.

## Proceso de razonamiento esperado

Un estudiante que llega en frío a "la aplicación de payments no
responde" no debería saltar directo al Deployment. Guíalo (si se
traba) por este orden, que refleja la chuleta de troubleshooting:

1. **Reproducir**: hacer `curl` al hostname de la Route. Confirmar la
   falla (connection refused, o una página de error tipo gateway,
   según el router); esto establece que realmente hay un problema, y
   más o menos de qué tipo.
2. **Route**: `oc get route payments-api` y `oc describe route
   payments-api`. La Route se ve bien configurada: apunta al Service
   `payments-api`, puerto `http`. Este es un callejón sin salida
   normal, aunque un poco frustrante; enseña a los estudiantes que una
   Route que se ve correcta no garantiza un camino que funcione.
3. **Service**: `oc get svc payments-api`. El Service existe, tiene
   una ClusterIP, y se ve bien a simple vista. El bug no es visible
   solo con `oc get svc`.
4. **Endpoints** (la capa que realmente revela el problema):
   ```bash
   oc get endpoints payments-api
   ```
   ```
   NAME           ENDPOINTS   AGE
   payments-api   <none>      12m
   ```
   Una lista de Endpoints vacía con Pods que se ven sanos en otro lado
   es la señal más fuerte de todo este lab. Los estudiantes que llegan
   hasta acá ya recorrieron la mayor parte del camino hacia la
   respuesta.
5. **Comparar el selector contra las labels del Pod**:
   ```bash
   oc get svc payments-api -o jsonpath='{.spec.selector}{"\n"}'
   # {"app":"payments-processor"}

   oc get pods -l app=payments-api --show-labels
   # confirma que los Pods tienen la label app=payments-api, no app=payments-processor
   ```
6. **Los Pods en sí**: `oc get pods -l app=payments-api` muestra los
   dos Pods `Running` y `1/1` Ready todo el tiempo: este es el detalle
   que debería redirigir a un estudiante que asumió al principio que
   los Pods eran los culpables, de vuelta hacia el Service.

## Causa raíz

El `spec.selector` del Service `payments-api` no coincide con la label
aplicada a los Pods del Deployment `payments-api`, así que el Service
enruta hacia ningún backend.

## Arreglo

```bash
oc patch svc payments-api -p '{"spec":{"selector":{"app":"payments-api"}}}'
```

## Validación

```bash
oc get endpoints payments-api
# -> dos IPs de Pod en el puerto 8080

HOST=$(oc get route payments-api -o jsonpath='{.spec.host}')
curl "http://${HOST}/api/pet"
# -> {"name":"payments-api","mood":80,"satiety":80,"energy":80,...}
```

## Notas de calificación para instructores

Un reporte completo debería:

- Nombrar específicamente el desajuste de selector del Service, no
  solo "el service estaba mal configurado".
- Mostrar evidencia de `oc get endpoints`, no solo de leer el Service
  o el Deployment en YAML (que el estudiante no debería haber abierto
  hasta terminar).
- Volver a probar vía la Route/`curl`, no solo vía `oc get endpoints`.

## Errores comunes

- Reiniciar o escalar el Deployment, o eliminar Pods, cuando nunca
  mostraron ningún problema: un buen momento para reforzar el punto
  del Lab 6 de que las acciones a nivel de Pod no arreglan problemas de
  Service o de configuración.
- "Arreglar" el desajuste editando las labels del Pod en el
  Deployment para que coincidan con el Service, en vez de corregir el
  Service. Ambos técnicamente restauran la conectividad, pero corregir
  el Service es la dirección correcta acá, ya que el labeling del
  Deployment es el consistente e intencional; señálalo explícitamente
  si ves a un estudiante tomar el otro camino.

## Reset

```bash
oc delete -f scenario/route.yaml -f scenario/service.yaml -f scenario/deployment.yaml --ignore-not-found
# después reaplica scenario/*.yaml para armar un incidente nuevo para otro intento
```
