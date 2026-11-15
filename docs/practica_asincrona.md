# Práctica asíncrona: revisión y evidencias

Revisión del 16 de octubre de 2026 basada en el README y los ejercicios del profesor. No se modificaron el diseño, los proveedores de tareas, el formulario ni el servicio HTTP.

Antes de trabajar se respaldaron las carpetas de práctica en:
C:\Users\Mauri\AppData\Local\Temp\taskflow_practica_20261016_130905

## Estado

| Ejercicio | Código y comprobación | Pendiente personal |
|---|---|---|
| 1.3 | Ejecutado; orden observado A, E, C, B, D | Predicción propia, explicación y captura |
| 1.6 | await corregido; error capturado; original comprobado en copia temporal | Capturas y explicación del error original |
| 1.7 | Secuencial y concurrente ejecutados; se añadió ejemplo dependiente separado | Ejecutar, registrar tiempos propios y explicar .wait |
| 1.8 | Ambas funciones ejecutadas y resultado comparado | Observar el indicador en Android o escritorio y capturar |

La versión original del 1.7 se conserva. El caso dependiente está en 1_7_futures_dependientes.dart y utiliza cargarPendientes(String perfil). Necesita esperar cargarPerfil antes de iniciar pendientes: no se pueden arrancar ambas llamadas simultáneamente con .wait cuando la segunda necesita el resultado de la primera.

## Resultados medidos por el agente

- 1.3: A, E, C, B, D. La predicción del agente se registró antes de ejecutar; no se atribuye a la estudiante.
- 1.6 corregido: Error controlado: Exception: Título vacío.
- 1.6 original: imprimió ¡Listo! y después terminó con excepción no controlada; código 255. El analizador detectó unawaited_futures.
- 1.7 secuencial: 5 s; Ana, 7.
- 1.7 concurrente: 3 s; Ana, 7.
- 1.7 dependiente: 5055 ms; Ana, 7.
- 1.8 sin isolate: 2560 ms; resultado 1199999997.
- 1.8 con isolate: 2658 ms; resultado 1199999997.
- flutter test test/practica_asincrona_test.dart: tres pruebas aprobadas.

Las mediciones del 1.8 corresponden a las funciones ejecutadas en Flutter test, no a una revisión visual de la app. No prueban que el indicador gire en un dispositivo. Un isolate permite separar el trabajo de CPU del hilo principal; no garantiza que el cálculo termine antes. Los tiempos variarán al repetirlos.

La salida capturada está en resultados_practica_asincrona.txt. La bitácora personal conserva sus campos pendientes. El caso dependiente se puede añadir a su tabla al ejecutarlo.

## Orden para las capturas

Ejecutar desde C:\ProyectosFlutter\taskflow. No hace falta copiar archivos.

1. Primero 1.3: leer el archivo y escribir una predicción propia antes de ejecutarlo.

```powershell
dart run practica_sesion1/1_3_orden_ejecucion.dart
```

Captura sugerida: Evidencias_Semana_14/07_orden_ejecucion.png.

2. Después 1.6 corregido:

```powershell
dart run practica_sesion1/1_6_await_olvidado.dart
```

Para comparar el original sin alterar el proyecto, la copia temporal ya preparada contiene su configuración de análisis:

```powershell
dart analyze "$env:TEMP\taskflow_await_original_semana14"
dart run "$env:TEMP\taskflow_await_original_semana14\await_original.dart"
```

La excepción del original es intencional. Capturas sugeridas: 08_await_original.png y 09_await_corregido.png.

3. Después 1.7:

```powershell
dart run practica_sesion1/1_7_futures_independientes.dart
dart run practica_sesion1/1_7_futures_dependientes.dart
```

Captura sugerida: 10_futures.png. Registrar los tiempos que aparezcan en tu propia ejecución.

4. Finalmente 1.8: iniciar TaskFlow en Windows o Android y abrir Experimento: isolates mediante el botón de ciencias. En Windows, si tienes las herramientas de compilación de escritorio configuradas:

```powershell
flutter run -d windows
```

Presionar Sin isolate, observar el indicador y capturar el resultado. Después repetir con Con isolate. Capturas sugeridas: 11_sin_isolate.png y 12_con_isolate.png. Para la evidencia de fluidez conviene una grabación o una descripción propia, porque una imagen fija no muestra si el indicador se detiene. No utilizar Chrome para Isolate.run.

## Verificación repetible

```powershell
flutter test test/practica_asincrona_test.dart
flutter analyze
```

El apoyo de IA se utilizó para revisar, añadir el ejemplo dependiente, preparar pruebas y registrar salidas reales. No se generaron capturas ni observaciones personales de la estudiante. No se avanzó a otras actividades.

Resultado final de flutter analyze: No issues found (4,0 s).
