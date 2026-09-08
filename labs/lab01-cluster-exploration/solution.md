# Lab 1: Solución

## 1-7. Navegación básica

```bash
oc whoami
oc project
oc get projects
oc get nodes
oc get pods
oc get deployments
oc get svc
oc get routes
```

`oc get projects` lista todos los projects que el usuario puede ver,
que pueden ser más de uno según el clúster. `oc project` (sin
argumentos) imprime el que está seleccionado actualmente.

## 8. sample-inventory

```bash
oc get pods -l app=sample-inventory
```

Hay **2** Pods, porque `sample-inventory` se desplegó con
`replicas: 2`.

Para encontrar el Deployment dueño sin leer el manifiesto:

```bash
oc get pod <nombre-del-pod> -o jsonpath='{.metadata.ownerReferences[0].name}'
```

Esto devuelve un nombre de ReplicaSet como `sample-inventory-<hash>`.
Ese ReplicaSet, a su vez, es dueño del Deployment `sample-inventory`:

```bash
oc get replicaset <nombre-del-replicaset> -o jsonpath='{.metadata.ownerReferences[0].name}'
```

Ubicación en los nodes:

```bash
oc get pods -l app=sample-inventory -o wide
```

La columna `NODE` muestra dónde cayó cada Pod. Es normal que el
scheduler distribuya los dos Pods en nodes distintos si hay más de un
node disponible con capacidad.

Labels:

```bash
oc get pods -l app=sample-inventory --show-labels
```

Deberías ver `app=sample-inventory` y `lab=lab01`, más labels
generadas por el sistema como `pod-template-hash`.

Qué Service selecciona estos Pods:

```bash
oc get svc sample-inventory -o jsonpath='{.spec.selector}'
```

Esto imprime `{"app":"sample-inventory"}`. Confírmalo de verdad
comparándolo contra las labels de los Pods de arriba, y verificando que
Endpoints realmente resuelve a IPs de Pod reales:

```bash
oc get endpoints sample-inventory
```

## 9. describe

`oc describe pod <nombre>` es el comando con más información de todo
este lab. Señala a los estudiantes la sección **Events** al final:
es la misma sección de la que van a depender mucho a partir del Lab 4.

## Errores comunes

- Asumir que un Service selecciona Pods "porque los nombres coinciden"
  en vez de comparar `spec.selector` contra las labels reales de los
  Pods.
- Confundir el nombre de un ReplicaSet con el de un Deployment: se ven
  parecidos (`sample-inventory-7d8f9c6b6d` vs `sample-inventory`) pero
  son objetos distintos.
- Olvidar `-o wide` y concluir que no hay forma de ver en qué node está
  un Pod.
