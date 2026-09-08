# Guía del Instructor: OpenShift Operations Fundamentals

Esta guía es solo para el instructor. Asume que ya leíste el `README.md`
raíz y `docs/prerequisites.md`.

## Antes del día uno

1. Corre `./scripts/validate-environment.sh` tú mismo contra el clúster
   de entrenamiento.
2. Para cada estudiante, corre:
   ```bash
   ./scripts/instructor-setup.sh <student_id>
   ```
   Esto crea `ocp-workshop-<student_id>` (si tu clúster no permite
   creación self-service de projects, este paso es obligatorio, no
   solo una conveniencia) y precarga los recursos que los Labs 1, 5 y 7
   necesitan que ya estén presentes. Los estudiantes nunca aplican esos
   manifiestos ellos mismos.
3. Dile a cada estudiante su `STUDENT_ID` y pídele que confirme con:
   ```bash
   export STUDENT_ID=<id>
   oc project ocp-workshop-${STUDENT_ID}
   ```

## Cronograma sugerido

| Día | Labs | Notas |
|---|---|---|
| 1 | 1, 2, 3, 4 | Fundamentos: explorar, desplegar, configurar, probes |
| 2 | 5, 6, 7 | Troubleshooting, rollout/rollback, incidente final |

---

## Lab 1: Exploración del clúster

- **Objetivo de aprendizaje:** navegar un clúster con `oc get`/`oc
  describe`; entender Project, Node, Pod, Deployment, Service, Route
  como conceptos antes de escribir cualquier YAML.
- **Duración estimada:** 25-30 minutos.
- **Dificultad esperada para el estudiante:** baja. Algunos estudiantes
  sin familiaridad con label selectors pueden necesitar un empujón en
  la pregunta 8.
- **Recursos creados:** ninguno por el estudiante. `sample-inventory`
  (Deployment, Service, Route, 2 réplicas) lo precarga
  `instructor-setup.sh`.
- **Salida esperada:** los estudiantes pueden indicar cantidad de Pods,
  Deployment dueño, ubicación en nodes, labels, y el Service que
  selecciona, todo a partir del estado real del clúster.
- **Errores comunes:** asumir que un Service selecciona un Pod porque
  los nombres coinciden, en vez de comparar `spec.selector` contra las
  labels reales del Pod; no conocer `-o wide` para la ubicación en
  nodes.
- **Pistas que puede dar el instructor:** "¿Qué te muestra `oc get pod
  -o yaml` que `oc get pod` no muestra?" (lleva a `ownerReferences`).
  "¿Cómo probarías que un Service realmente está conectado a un Pod, en
  vez de solo adivinar por el nombre?" (lleva a comparar
  `spec.selector` contra las labels del Pod, y a `oc get endpoints`).
- **Solución completa:** ver
  `labs/lab01-cluster-exploration/solution.md`.
- **Procedimiento de reset:** ninguno necesario; `sample-inventory`
  persiste durante todo el workshop. Las instrucciones de reset
  completo están en `scripts/reset-student.sh` si alguna vez hace
  falta.

---

## Lab 2: Desplegar una Aplicación Existente

- **Objetivo de aprendizaje:** desplegar una imagen ya construida vía
  Deployment / Service / Route sin ningún paso de build; entender cómo
  el escalado relaciona Deployment, ReplicaSet y Pods.
- **Duración estimada:** 35-40 minutos.
- **Dificultad esperada para el estudiante:** baja-media. La relación
  entre el selector del Service y las labels del Pod template es el
  primer concepto genuinamente nuevo.
- **Recursos creados:** Deployment, Service, Route, todos llamados
  `hello-openshift`.
- **Salida esperada:** `curl` contra la Route devuelve "Hello from
  OpenShift Operations Workshop"; escalar a 3 y volver a 1 deja
  exactamente un Pod sano.
- **Errores comunes:** dejar `image: ""` sin completar y no leer el
  error resultante; confundir el `targetPort` de la Route (un nombre de
  puerto del Service) con el puerto del contenedor; asumir que el Pod
  que sobrevive al escalar de vuelta a 1 réplica es determinístico (no
  lo es).
- **Pistas que puede dar el instructor:** "¿Con qué necesita coincidir
  el `selector` del Service?" "¿El `targetPort` de una Route habla del
  contenedor, o del Service?"
- **Solución completa:** ver
  `labs/lab02-deploy-application/solution.md`.
- **Procedimiento de reset:**
  ```bash
  oc delete -f labs/lab02-deploy-application/manifests/route.yaml \
             -f labs/lab02-deploy-application/manifests/service.yaml \
             -f labs/lab02-deploy-application/manifests/deployment.yaml \
             --ignore-not-found
  ```

---

## Lab 3: ConfigMaps y Secrets

- **Objetivo de aprendizaje:** externalizar configuración a un
  ConfigMap y observar el rollout resultante; crear un Secret,
  inspeccionar sus metadata, y entender que base64 es codificación, no
  encriptación.
- **Duración estimada:** 30 minutos.
- **Dificultad esperada para el estudiante:** baja-media.
- **Recursos creados:** ConfigMap `hello-openshift-config`, Secret
  `hello-openshift-credentials`, Deployment `hello-openshift`
  actualizado.
- **Salida esperada:** `curl` contra la Route devuelve "Hello from a
  ConfigMap"; `oc exec` dentro del Pod muestra ambos valores del
  Secret en el entorno.
- **Errores comunes:** esperar que editar un ConfigMap in place, solo
  eso, dispare un rollout nuevo (no lo hace: solo lo hace el Deployment
  cambiado); esperar que los valores del Secret aparezcan en la
  respuesta HTTP (no aparecen: `hello-openshift` solo refleja
  `RESPONSE`).
- **Pistas que puede dar el instructor:** "Si solo cambiaste el
  ConfigMap y no el Deployment, ¿los Pods existentes se darían
  cuenta?" "¿De dónde lee la aplicación `RESPONSE` ahora?"
- **Solución completa:** ver
  `labs/lab03-configmaps-secrets/solution.md`.
- **Procedimiento de reset:**
  ```bash
  oc delete -f labs/lab03-configmaps-secrets/manifests/deployment.yaml \
             -f labs/lab03-configmaps-secrets/manifests/secret.yaml \
             -f labs/lab03-configmaps-secrets/manifests/configmap.yaml \
             --ignore-not-found
  ```

---

## Lab 4: Health Probes

- **Objetivo de aprendizaje:** distinguir "el contenedor está
  corriendo" de "la aplicación está lista"; leer fallas de probe a
  partir de los events del Pod.
- **Duración estimada:** 30-35 minutos.
- **Dificultad esperada para el estudiante:** media. Este es el primer
  lab donde un Pod se ve sano a primera vista (`Running`) mientras en
  realidad está roto (`0/1` Ready).

### Cadena de troubleshooting (funciona -> se rompe -> se repara)

```
SÍNTOMA        El Pod se queda Running, la columna READY trabada en 0/1
OBSERVACIÓN    oc get pods -l app=hello-openshift muestra 0/1 Ready, los reinicios se quedan en 0
EVIDENCIA      oc describe pod: "Readiness probe failed: ... dial tcp ...:8081: connection refused"
CAUSA RAÍZ     readinessProbe.httpGet.port es 8081; el contenedor solo escucha en 8080
ARREGLO        volver a poner readinessProbe.httpGet.port en 8080
VALIDACIÓN     oc get pods muestra 1/1 Ready; el conteo de reinicios no cambió
```

- **Recursos creados:** Deployment `hello-openshift` actualizado
  (agrega probes), después la variante rota, después la variante
  reparada.
- **Errores comunes:** recurrir primero a `oc logs` en vez de a la
  sección Events de `oc describe pod`; no notar que el conteo de
  reinicios se queda en 0, que es la señal clave de que esto es un
  problema de readiness y no un crash.
- **Pistas que puede dar el instructor:** "¿El contenedor realmente
  está fallando al correr, o algo más está decidiendo que no está
  listo?" "¿Qué te dice el conteo de reinicios?"
- **Solución completa:** ver `labs/lab04-health-probes/solution.md`.
- **Procedimiento de reset:**
  ```bash
  oc apply -f labs/lab04-health-probes/manifests/deployment.yaml
  ```

---

## Lab 5: Troubleshooting

- **Objetivo de aprendizaje:** diagnosticar de forma independiente
  cuatro modos de falla distintos usando solo `oc
  get`/`describe`/`logs`/`events`.
- **Duración estimada:** 45-50 minutos.
- **Dificultad esperada para el estudiante:** media-alta, en
  particular el Escenario 3.
- **Recursos creados:** ninguno por el estudiante: `frontend`,
  `orders`, `catalog` y `notifications` los precargan
  `instructor-setup.sh`/`reset-student.sh`.

### Escenario 1: `frontend` (ImagePullBackOff)

```
SÍNTOMA        El Pod nunca llega a Running
OBSERVACIÓN    oc get pods -l app=frontend muestra ImagePullBackOff
EVIDENCIA      oc describe pod: "Failed to pull image ...:v9.9.9 ... not found"
CAUSA RAÍZ     El Deployment referencia un tag inexistente (v9.9.9)
ARREGLO        oc set image deployment/frontend frontend=docker.io/openshift/hello-openshift:v3.9.0
VALIDACIÓN     oc get pods -l app=frontend muestra Running, 1/1
```

### Escenario 2: `orders` (CrashLoopBackOff)

```
SÍNTOMA        El Pod se reinicia repetidamente, RESTARTS sigue subiendo
OBSERVACIÓN    oc get pods -l app=orders muestra CrashLoopBackOff
EVIDENCIA      oc logs <pod> --previous: "orders: fatal configuration error, exiting"
               oc describe pod: Last State Terminated, Reason Error, Exit Code 1
CAUSA RAÍZ     el command del contenedor sale a propósito con 1 justo después de loguear
ARREGLO        reemplazar el command por un proceso de larga duración
VALIDACIÓN     oc get pods -l app=orders muestra Running, 1/1, los reinicios dejan de subir
```

Señala a los estudiantes que `oc logs <pod>` solo puede no mostrar nada
útil si un contenedor nuevo ya reemplazó al que crasheó: `--previous`
es la herramienta hecha exactamente para esa situación.

### Escenario 3: `catalog` (Service sin endpoints)

```
SÍNTOMA        curl contra la Route de catalog falla a pesar de que los Pods están Running
OBSERVACIÓN    oc get pods -l app=catalog: Running, 1/1 (ambas réplicas)
EVIDENCIA      oc get endpoints catalog: <none>
               oc get svc catalog selector: app=catalog-backend
               oc get pods -l app=catalog --show-labels: app=catalog
CAUSA RAÍZ     el selector del Service no coincide con las labels del Pod
ARREGLO        oc patch svc catalog -p '{"spec":{"selector":{"app":"catalog"}}}'
VALIDACIÓN     oc get endpoints catalog lista IPs de Pod; curl funciona
```

Este es el escenario que más cuesta a la mayoría de los estudiantes,
justamente porque no hay nada mal con los Pods. Reserva tiempo extra
acá y espera tener que empujar a los estudiantes que se fijan en los
Pods.

### Escenario 4: `notifications` (Falla de readiness)

```
SÍNTOMA        El Pod está Running pero 0/1 Ready
OBSERVACIÓN    oc get pods -l app=notifications
EVIDENCIA      oc describe pod: "Readiness probe failed: ... :8081: connection refused"
CAUSA RAÍZ     readinessProbe.httpGet.port es 8081 en vez de 8080
ARREGLO        oc patch deployment notifications --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8080}]'
VALIDACIÓN     oc get pods -l app=notifications muestra 1/1 Ready
```

- **Errores comunes:** aplicar un arreglo al objeto equivocado (por
  ejemplo, editar las labels del Pod en vez del selector del Service
  en el Escenario 3); asumir que `RESTARTS` subiendo significa que todo
  problema es un crash.
- **Pistas que puede dar el instructor:** para cada escenario, señala a
  los estudiantes la capa específica de la chuleta (Route/Service/
  Endpoints/Pod/Container/Readiness) que coincide con el síntoma, sin
  nombrar el objeto responsable.
- **Solución completa:** ver `labs/lab05-troubleshooting/solution.md`.
- **Procedimiento de reset:**
  ```bash
  oc delete all -l lab=lab05 -n ocp-workshop-<student_id>
  ./scripts/instructor-setup.sh <student_id>   # o reset-student.sh, corrido por el estudiante
  ```

---

## Lab 6: Rollout y Rollback

- **Objetivo de aprendizaje:** realizar una actualización rolling
  normal; reconocer un rollout trabado; usar `oc rollout undo`
  correctamente; entender por qué eliminar Pods no es un arreglo para
  un Deployment mal configurado.
- **Duración estimada:** 25-30 minutos.
- **Dificultad esperada para el estudiante:** baja-media.
- **Recursos creados:** Deployment/Service/Route `hello-openshift`
  (revisión 1), después las revisiones 2 y 3 (la 3 es
  deliberadamente rota).

```
SÍNTOMA        oc rollout status nunca se completa después de publicar la "versión 3"
OBSERVACIÓN    oc get pods -l app=hello-openshift: un Pod nuevo trabado en ImagePullBackOff,
               los Pods viejos de la revisión 2 siguen Running (la Route sigue sirviendo v2)
EVIDENCIA      oc describe pod en el Pod nuevo: imagen ...:v9.9.9 not found
CAUSA RAÍZ     la revisión 3 referencia un tag de imagen inexistente
ARREGLO        oc rollout undo deployment/hello-openshift
VALIDACIÓN     oc rollout status reporta éxito; curl devuelve "Application version 2"
```

- **Errores comunes:** eliminar el Pod trabado esperando que eso
  resuelva el problema (no lo hace: el ReplicaSet lo recrea con el
  mismo template roto); correr `oc rollout undo` más de una vez y
  pasarse de la revisión 2.
- **Pistas que puede dar el instructor:** "¿La Route está sirviendo
  algo en este momento? ¿Qué te dice eso sobre qué ReplicaSet sigue
  activo?" "¿Qué cambia exactamente `undo`, comparado con `restart`?"
- **Solución completa:** ver `labs/lab06-rollout-rollback/solution.md`.
- **Procedimiento de reset:**
  ```bash
  oc apply -f labs/lab06-rollout-rollback/manifests/deployment.yaml
  ```

---

## Lab 7: Incidente Final

- **Objetivo de aprendizaje:** correr una investigación de incidente
  completa y sin guía, desde el síntoma hasta un arreglo validado, y
  escribirla.
- **Duración estimada:** 30 minutos.
- **Dificultad esperada para el estudiante:** media. La dificultad acá
  viene, a propósito, de la falta de pistas, no de un concepto técnico
  nuevo: cada herramienta necesaria ya se usó en los Labs 5 y 6.
- **Recursos creados:** ninguno por el estudiante: `payments-api`
  (Deployment, Service, Route) lo precargan
  `instructor-setup.sh`/`reset-student.sh`.

```
SÍNTOMA        La aplicación de payments no responde (curl contra la Route falla)
OBSERVACIÓN    oc get route/svc/pods de payments-api se ven bien por separado;
               los Pods muestran Running, 1/1... espera, en realidad Running,
               revisa Endpoints después
EVIDENCIA      oc get endpoints payments-api: <none>
               oc get svc payments-api selector: app=payments-processor
               oc get pods -l app=payments-api --show-labels: app=payments-api
CAUSA RAÍZ     el selector del Service (app=payments-processor) no coincide con
               las labels del Pod del Deployment (app=payments-api)
ARREGLO        oc patch svc payments-api -p '{"spec":{"selector":{"app":"payments-api"}}}'
VALIDACIÓN     oc get endpoints payments-api lista IPs de Pod; curl contra la Route funciona
```

Esta es, a propósito, la misma clase de falla que el Escenario 3 del
Lab 5, sin que se les diga. Un buen tema de conversación para el
instructor después del lab es que el reconocimiento de patrones
operativos (no comandos nuevos) es lo que hizo más rápida esta segunda
vez.

- **Errores comunes:** reiniciar/escalar el Deployment o eliminar Pods
  cuando nunca hubo nada roto en ellos; "arreglar" el desajuste
  reetiquetando los Pods para que coincidan con el Service, en vez de
  corregir el Service (funciona, pero es la dirección equivocada:
  señálalo si lo ves).
- **Pistas que puede dar el instructor (solo si un grupo está
  realmente trabado después de ~15 minutos):** "Ya confirmaste que la
  Route y los Pods están bien por separado, ¿qué hay entre los dos?"
- **Solución completa:** ver
  `labs/lab07-final-incident/solution.md`, incluyendo notas de
  calificación para el reporte escrito.
- **Procedimiento de reset:**
  ```bash
  oc delete -f labs/lab07-final-incident/scenario/route.yaml \
             -f labs/lab07-final-incident/scenario/service.yaml \
             -f labs/lab07-final-incident/scenario/deployment.yaml \
             --ignore-not-found
  oc apply -f labs/lab07-final-incident/scenario/
  ```

---

## Limpieza de fin de workshop

Por estudiante:

```bash
./scripts/instructor-reset.sh <student_id> --full
```

O, si los projects deben simplemente eliminarse al terminar el
workshop:

```bash
oc delete project ocp-workshop-<student_id>
```

Nunca corras un comando de limpieza que no esté acotado al nombre de
project de un estudiante específico.
