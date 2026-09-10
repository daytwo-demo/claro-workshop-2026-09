# Lab 7: Incidente Final

**Duración:** aproximadamente 30 minutos

## Objetivo

Correr una investigación de incidente completa y sin guía, desde un
único síntoma hasta un arreglo validado, usando todo lo de los seis
labs anteriores.

## Reporte de incidente

> **La aplicación de payments no responde**
>
> Los usuarios reportan que la aplicación de payments no responde.

Se te da únicamente:

- **Namespace:** tu propio project (se llama igual que tu usuario de login)
- **Nombre de la aplicación:** `payments-api`
- **URL de la Route:** consíguela tú mismo:

```bash
oc get route payments-api -o jsonpath='{.spec.host}'
```

Nada más se te da. En particular, no se te dice qué objeto está roto,
y no deberías abrir ningún manifiesto bajo `scenario/` hasta haber
completado tu investigación y escrito tu reporte: hacerlo antes anula
el propósito de este ejercicio.

## Tasks

> Todos los comandos de este lab se corren desde
> `labs/lab07-final-incident`.

1. Reproduce el síntoma tú mismo (`curl` a la Route, o ábrela en un
   navegador).
2. Investiga de forma metódica. Baja capa por capa por el camino de la
   petición, de la misma forma en que lo harías en un incidente real
   de guardia: [la chuleta de troubleshooting](../../docs/troubleshooting-cheatsheet.md)
   describe ese orden si quieres un recordatorio de las capas
   involucradas, sin decirte cuál está fallando acá.
3. Una vez que identifiques la causa raíz, corrígela.
4. Valida el arreglo desde el punto de vista del usuario (la Route),
   no solo desde el objeto que cambiaste.
5. Escribe un reporte de incidente breve (con unas pocas frases por
   sección alcanza):

   1. **Síntoma observado**: ¿qué viste al reproducir el problema?
   2. **Evidencia recolectada**: ¿qué comandos corriste, y qué mostró
      cada uno?
   3. **Causa raíz**: la razón específica y precisa por la que la
      aplicación no respondía.
   4. **Acción correctiva**: exactamente qué cambiaste.
   5. **Validación realizada**: cómo confirmaste que el arreglo
      realmente funcionó.

## Comandos útiles

Ya conoces todos estos de los Labs 5 y 6:

```bash
oc get route
oc describe route <nombre>
oc get svc
oc describe svc <nombre>
oc get endpoints <nombre>
oc get pods
oc describe pod <nombre>
oc logs <pod>
oc get events --sort-by=.lastTimestamp
```

## Validación

- La Route responde correctamente con `curl`.
- Tu reporte de incidente nombra una causa raíz específica, no una
  descripción vaga como "el pod estaba roto".
- El paso de "validación realizada" de tu reporte realmente vuelve a
  probar el síntoma original (la Route), no solo el objeto que
  cambiaste.

## Limpieza

```bash
oc delete -f scenario/route.yaml -f scenario/service.yaml -f scenario/deployment.yaml
```
