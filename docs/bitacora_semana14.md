# Bitácora de la Semana 14

Nombre:
Fecha:
Versión de Flutter y plataforma:

Completar con resultados propios. Los resultados esperados de las tablas no son resultados observados.

## Ejercicio 1.3: orden de ejecución

Antes de ejecutar:
- Mi predicción:
- Motivo:

Comando: dart run practica_sesion1/1_3_orden_ejecucion.dart

Después de ejecutar:
- Salida real:
- Diferencias con mi predicción:
- Explicación de eventos y microtareas:
- Captura de terminal:

## Ejercicio 1.6: await olvidado

La copia del proyecto incluye la corrección. El original está en el proyecto base del profesor.

- Salida del original:
- Aviso de unawaited_futures sobre el original:
- Salida de la versión corregida:
- Por qué el try necesita await:
- Capturas:

No quitar await del proyecto entregable para generar evidencias. Utilizar una copia temporal del ejercicio original.

## Ejercicio 1.7: Futures independientes

Comando: dart run practica_sesion1/1_7_futures_independientes.dart

| Forma | Tiempo observado | Salida real |
|---|---|---|
| Secuencial | Pendiente | Pendiente |
| Concurrente con .wait | Pendiente | Pendiente |

- Por qué cambian los tiempos:
- Si cargarPendientes necesita el perfil, qué debe esperarse primero:
- Prueba en copia temporal con cargarPendientes(String perfil):
- Resultado observado y explicación de por qué no puede arrancar simultáneamente con cargarPerfil:
- Captura:

## Ejercicio 1.8: isolates

Abrir Experimento: isolates desde la pantalla principal, en Android o escritorio.

| Ejecución | Resultado numérico | Tiempo mostrado | Comportamiento del indicador |
|---|---|---|---|
| Sin isolate | Pendiente | Pendiente | Pendiente |
| Con isolate | Pendiente | Pendiente | Pendiente |

- Tiempo aproximado de congelamiento:
- Comparación de resultados:
- Por qué async no evita por sí solo el bloqueo por CPU:
- Capturas o grabación:

## Cuatro pruebas de error

Estas categorías siguen lo autorizado por la estudiante. Comparar con Canvas si el profesor especifica escenarios adicionales. Usar respuestas controladas para HTTP, timeout y JSON; desconectar la red en la app para la prueba manual de conexión. No dejar URLs incorrectas en el entregable.

| Caso | Preparación | Resultado esperado | Resultado observado | Evidencia |
|---|---|---|---|---|
| HTTP fallido | Respuesta 404 o 500 | Mensaje y Reintentar | Pendiente | Pendiente |
| Sin conexión | Desconectar la red y recargar | Mensaje de conexión | Pendiente | Pendiente |
| Timeout | Respuesta demorada más de 10 segundos | Mensaje de tiempo de espera | Pendiente | Pendiente |
| JSON incorrecto | JSON mal formado o raíz distinta de lista | Mensaje de datos incorrectos | Pendiente | Pendiente |

Comprobación adicional: POST fallido debe conservar las tareas visibles y mostrar un aviso. Resultado y captura:

## Ocho casos JSON

Comando: flutter test test/tarea_json_test.dart

| Caso | Entrada o acción | Resultado esperado | Resultado observado |
|---|---|---|---|
| 1 | id 7, title con espacios, completed true | ID 7, título normalizado, true y valores predeterminados | Pendiente |
| 2 | Solo title válido | ID null, completada false | Pendiente |
| 3 | Sin title | FormatException | Pendiente |
| 4 | title solo espacios | FormatException | Pendiente |
| 5 | title numérico | FormatException | Pendiente |
| 6 | id de texto | FormatException | Pendiente |
| 7 | completed de texto | FormatException | Pendiente |
| 8 | toJson sobre tarea completa | Solo title, completed y userId 1 | Pendiente |

- Captura de ejecución:
- Casos propuestos con apoyo de IA y revisados personalmente:
- Explicación propia de las validaciones:

## Capturas de funcionamiento

- Resumen local conservado y acceso a nube.
- Tareas remotas cargadas y actualización al deslizar.
- Formulario original y validación de campos.
- Resultado de POST y aviso sobre persistencia simulada.
- Error y recuperación con Reintentar.
- flutter analyze y flutter test.

No se incluyen capturas ni observaciones manuales inventadas.
