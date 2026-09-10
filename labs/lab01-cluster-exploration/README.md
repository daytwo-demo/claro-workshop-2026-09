# Lab 1: Exploración del clúster

**Duración:** aproximadamente 25-30 minutos

## Objetivo

Familiarizarte con la navegación de un clúster de OpenShift: entender
qué es un Project, un Node, un Pod, un Deployment y un Service, y
practicar cómo leer su estado con `oc get` y `oc describe`.

## Escenario

Tu instructor ya desplegó una pequeña aplicación de ejemplo llamada
`sample-inventory` en tu project. No has visto su manifiesto, y eso es
intencional: para este lab, vas a descubrir todo sobre ella usando
solo comandos `oc`, de la misma forma en que investigarías una
aplicación desconocida en un clúster al que acabas de unirte.

## Tasks

Si abriste tu terminal desde el ícono de la consola web (Web Terminal),
vas a ver un Pod extra en tu project (algo como
`workspace<id>-<hash>`): es el que corre tu propia terminal, no algo
que crearon los labs. Ignóralo en las cuentas de abajo.

1. Confirma quién eres y en qué project estás trabajando.

2. Lista los projects a los que tienes acceso. Confirma que puedes ver
   (y que estás usando) el project que te asignó tu instructor (se
   llama igual que tu usuario de login).

3. Lista los nodes del clúster. No se espera que administres nodes
   como usuario regular, pero deberías poder ver cuántos existen y su
   estado.

4. Lista los Pods de tu project. Anota cuántos hay (sin contar el de
   tu propia terminal, si corresponde).

5. Lista los Deployments de tu project.

6. Lista los Services de tu project.

7. Lista las Routes de tu project.

8. Para la aplicación `sample-inventory`, responde lo siguiente usando
   `oc get` y `oc describe` (no te limites a leer el archivo del
   manifiesto: descúbrelo a partir del estado real del clúster):

   - ¿Cuántos Pods existen actualmente para esta aplicación?
   - ¿Qué Deployment es dueño de esos Pods? ¿Cómo puedes saberlo, a
     partir de los propios metadata del Pod, qué Deployment (y qué
     ReplicaSet) lo creó?
   - ¿En qué node corre cada Pod?
   - ¿Qué labels tiene cada Pod?
   - ¿Qué Service selecciona estos Pods? ¿Cómo lo confirmarías, en vez
     de asumirlo por el nombre?

9. Preséntate con `oc describe` en cada tipo de objeto (`pod`,
   `deployment`, `service`, `route`) al menos una vez. Nota qué
   información adicional te muestra `describe` que `get` no muestra,
   en particular la sección **Events** al final de `oc describe pod`.

## Comandos útiles

Vas a necesitar la mayoría de estos en algún momento del lab. Averigua
qué pregunta responde cada uno, en vez de correrlos en un orden fijo:

```bash
oc whoami
oc project
oc get projects
oc get nodes
oc get pods
oc get pods -o wide
oc get pods --show-labels
oc get deployments
oc get svc
oc get routes
oc describe pod <nombre>
oc describe deployment <nombre>
oc describe svc <nombre>
```

Tip: `oc get <tipo> -o yaml` te muestra la definición completa del
objeto, incluyendo `ownerReferences`, útil para responder "¿qué
Deployment es dueño de este Pod?" sin adivinar solo por el nombre.

## Validación

Deberías poder responder, en voz alta o por escrito, cada pregunta de
la sección Tasks sin abrir ningún archivo YAML de este repositorio.

## Limpieza

Nada que limpiar. `sample-inventory` se queda en tu project; lo vas a
volver a ver como contexto de fondo en labs posteriores, pero ningún
lab posterior depende de él.
