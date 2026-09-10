# Lab 5: Troubleshooting

**Duración:** aproximadamente 45-50 minutos

## Objetivo

Diagnosticar cuatro fallas de aplicación independientes y realistas
usando solo `oc get`, `oc describe`, `oc logs` y `oc get events`: el
mismo set de herramientas que usarías en un incidente real. Cada
escenario tiene una única causa raíz, determinística.

## Escenario

Tu instructor desplegó cuatro pequeñas aplicaciones en tu project,
cada una con un problema sin relación con las demás. Trabaja en orden.
Para cada una: resiste la tentación de abrir los archivos de manifiesto
bajo `scenarios/` antes de haber armado una hipótesis a partir del
estado real del clúster; ese es justamente el punto del ejercicio.
Úsalos después para verificar tu razonamiento.

Las cuatro aplicaciones son: `frontend`, `orders`, `catalog` y
`notifications`.

## Tasks

> Todos los comandos de este lab se corren desde
> `labs/lab05-troubleshooting`.

### Escenario 1: `frontend`

```bash
oc get pods -l app=frontend
```

Algo está impidiendo que este Pod arranque. Averigua qué, usando
`oc describe pod` y `oc get events`. Identifica la razón exacta que
reporta el clúster, y después corrige el Deployment para que el Pod
arranque correctamente.

Familia de pista: mira la referencia de imagen del contenedor y cómo
describe el clúster sus intentos de obtenerla.

### Escenario 2: `orders`

```bash
oc get pods -l app=orders
```

Este Pod se reinicia sin parar. Determina:

- ¿Qué exit code está reportando el contenedor?
- ¿Qué imprimió el contenedor antes de salir? (Cuidado: para cuando lo
  revises, puede que ya haya un contenedor nuevo corriendo, todavía sin
  logs propios; necesitas los logs de la instancia *anterior*.)

Familia de pista: `oc logs` tiene una opción hecha exactamente para
esta situación.

### Escenario 3: `catalog`

```bash
oc get route catalog
curl http://<host-de-la-route-de-arriba>
```

La Route existe, y el Service existe, pero las peticiones fallan.
Traza el camino de la petición desde la Route hasta el Service y hasta
los Pods reales, revisando cada capa por turno, hasta encontrar dónde
se rompe la cadena. Después corrige el objeto responsable.

Familia de pista: hay un objeto entre un Service y sus Pods que te
dice exactamente qué backends son (o no son) alcanzables a través de
ese Service.

### Escenario 4: `notifications`

```bash
oc get pods -l app=notifications
```

El Pod está `Running`, pero no acepta tráfico. Determina por qué,
usando la misma distinción que practicaste en el Lab 4 entre "el
proceso está vivo" y "la aplicación está lista". Corrige el campo
responsable.

## Comandos útiles

```bash
oc get pods -l app=<nombre>
oc describe pod -l app=<nombre>
oc logs <pod>
oc logs <pod> --previous
oc get events --sort-by=.lastTimestamp
oc get svc <nombre>
oc get endpoints <nombre>
oc get pods -l app=<nombre> --show-labels
oc get route <nombre>
```

## Validación

Para cada escenario, después de tu arreglo:

- `frontend`: `oc get pods -l app=frontend` muestra `Running` y `1/1`.
- `orders`: `oc get pods -l app=orders` muestra `Running` y `1/1`, con
  un conteo de `RESTARTS` estable (que ya no sigue subiendo).
- `catalog`: `oc get endpoints catalog` lista IPs reales de Pod, y
  `curl` contra la Route funciona.
- `notifications`: `oc get pods -l app=notifications` muestra `1/1`
  Ready.

## Limpieza

No hace falta antes del Lab 6, que usa su propio nombre de aplicación.
Si quieres eliminar estas cuatro aplicaciones de tu project:

```bash
oc delete all -l lab=lab05
```
