# Semana 19, sesión 1: nota a propuesta

La integración usa FirebaseAI.googleAI(), GenerativeModel.generateContent,
Content.system/text y GenerationConfig con responseMimeType y Schema.object,
verificados en el código local de firebase_ai 5.1.0. No hay agente, herramientas
ni ejecución automática de acciones. Solo Guardar tarea en el formulario existente
incorpora la propuesta a la lista local. ML Kit conserva su flujo.

Contrato: titulo (3–60 caracteres), descripcion (hasta 200), fecha_limite
(YYYY-MM-DD o null si ausente/ambigua). La validación rechaza fechas inexistentes,
pasadas y posteriores al límite del selector existente (1 de enero del año actual
más dos). Usa el día local del dispositivo; confirma su reloj y zona horaria.
La salida generada siempre requiere revisión humana; el esquema no garantiza
que la interpretación semántica sea correcta.

Modelo predeterminado: gemini-3.5-flash-lite. Se puede cambiar sin editar código con
--dart-define=GEMINI_MODEL=MODELO_DISPONIBLE. Comprobar disponibilidad y cuota
en el proyecto. No se incluyen claves ni secretos de App Check en código.

## Comparación reproducible

Fijar hoy = 2026-11-15 en la prueba del servicio. La línea base propuestaLocal
copia la primera línea como título (máximo 60), copia hasta 200 caracteres como
descripción y busca una fecha ISO. No interpreta expresiones relativas.

| Nota | Fecha local | Interpretación esperada de Gemini | Resultado Gemini real |
|---|---|---|---|
| Entregar informe el 2026-11-20 | 2026-11-20 | Fecha 2026-11-20 y título resumido | Pendiente |
| Mañana estudiar Flutter | null | Fecha 2026-11-16 | Pendiente |
| Organizar apuntes | null | Fecha null; no inventar vencimiento | Pendiente |

Las salidas locales se verifican con pruebas unitarias. Para comparar Gemini,
ejecutar las tres notas con la misma fecha de referencia (o actualizar mañana
al día siguiente de la prueba real). Registrar título, descripción, fecha,
validez JSON, correcciones humanas y tiempo de espera por método. Repetir tres
veces por nota para observar variación. No se atribuyen resultados todavía no
medidos a Gemini; no se ha realizado ninguna llamada real en esta sesión.

## Validación manual pendiente

Desde PowerShell en C:\ProyectosFlutter\taskflow:

```powershell
flutter analyze
flutter test
```

Cuando decidas iniciar un emulador Android manualmente:

```powershell
flutter devices
flutter run --debug -d <ID_ANDROID>
```

Sustituir el marcador por el ID real. Registrar el secreto debug de App Check
según docs/app_check_desarrollo.md; nunca añadirlo a Git. No cambiar enforcement.
Abrir el icono Nota con Gemini en la barra superior; probar las tres notas,
revisar/corregir, cancelar y confirmar. Probar sin internet y reintentar al
recuperarlo. Comprobar que solo se guarda tras confirmación, y que escanear
con ML Kit sigue funcionando. Un timeout limita la espera de UI, pero no cancela
la solicitud remota. Evitar reintentos repetidos que consuman cuota.

Documentación: https://firebase.google.com/docs/ai-logic/generate-structured-output

## Diagnóstico de espera (debug)

Espera de UI: 120 segundos (antes 30). No cancela la solicitud remota.
No reintentar repetidamente: el observador registra también errores tardíos.
En debug se solicita primero un token App Check con un límite de 20 segundos,
sin imprimirlo. Esto comprueba el intercambio de tokens, no solo activate().
No se cambia el proveedor, enforcement ni la inicialización de Firebase.

Filtrar la consola por `[TaskFlow Gemini`. Se registran etapa, tiempo, tipo y
código permitido, nunca nota, respuesta, mensaje crudo, cabeceras ni tokens:

- app_check_token: si falla aquí, revisar registro del secreto y logs nativos
  de App Check localmente. No compartir los mensajes que contienen el secreto.
- generate_content: App Check ya devolvió token; la generación incluye la
  obtención de cabeceras por el SDK, conexión HTTP y espera del servidor.
  El marcador no prueba que el servidor haya recibido la petición.
- leer_respuesta / validacion_json: hubo respuesta; revisar tipo y código
  para distinguir bloqueo/parseo de la validación de nuestra propuesta.
- error_origen_incluso_si_tardio: el error llegó después o antes del límite
  de UI. Conservar los registros del mismo intento; no lanzar otro enseguida.

FirebaseAIException 5.1.0 no expone una propiedad code. Se extraen únicamente
códigos reconocidos de su mensaje; si no existen se muestra
NO_EXPUESTO_POR_SDK. No se inventa un código HTTP ni se imprime el mensaje.
Un TIMEOUT_LOCAL no demuestra que el dispositivo carezca de internet.

Ejecutar `flutter analyze` y `flutter test` manualmente. Hacer un reinicio
completo de la aplicación con `flutter run --debug -d <ID_ANDROID>` para
repetir la inicialización. Probar una sola nota sencilla. Esperar los registros
antes de reintentar. Compartir únicamente las líneas con el prefijo anterior.
La configuración local coincide con taskflow-nancy; disponibilidad por proyecto,
cuota, permisos y éxito real requieren esta prueba conectada.
## Observación temporal del POST real

En debug, generativeModel recibe ClienteHttpDiagnostico mediante el parámetro
público httpClient. Se reenvía el mismo BaseRequest y se observa el stream de
respuesta sin consumirlo previamente. No se registran URLs, valores de cabeceras,
mensajes crudos, notas ni cuerpos. Solo eventos, tiempos, estado, bytes y una
clasificación cerrada de transporte (más código OS numérico si existe).

Ejecutar manualmente:

```powershell
flutter analyze
flutter test
flutter run --debug -d <ID_ANDROID> -t lib/main.dart
```

Sustituir el marcador por el ID del emulador ya iniciado. Probar una sola nota y
filtrar por [TaskFlow HTTP #N], con el mismo N de [TaskFlow Gemini #N].

- Sin send_entrada: el SDK todavía no entregó la petición al transporte; revisar
  la etapa SDK (incluida obtención de cabeceras).
- send_entrada seguido de error_antes_cabeceras: conexión, envío o espera inicial;
  este nivel no separa esos tres tramos. Examinar transporte y os_codigo.
- cabeceras_recibidas: hubo respuesta HTTP; el estado no prueba que el cuerpo
  haya terminado ni que la generación sea válida.
- primer_fragmento y error_lectura: fallo mientras se recibe el cuerpo.
- lectura_finalizada: el stream terminó; revisar también si hubo error_lectura
  antes (un stream puede emitir error y luego done). Revisar después los eventos
  del SDK y validación de propuesta.

Los ms se miden desde send; no incluyen la construcción previa de cabeceras.
La instrumentación sigue observando peticiones tardías sin cambiar el timeout
local de 120 segundos ni entregar resultados tardíos a la interfaz.
El cliente se cierra al terminar realmente la generación o fallar esta, no al
vencer la espera de UI. No hay reintentos añadidos.

Para deshabilitar sin editar código:

```powershell
flutter run --debug -d <ID_ANDROID> -t lib/main.dart --dart-define=GEMINI_HTTP_DIAGNOSTICO=false
```

En profile/release nunca se crea el cliente de diagnóstico. Para retirarlo,
eliminar su import, creación, parámetro httpClient y cierre en propuestas_tarea,
y retirar cliente_http_diagnostico.dart y sus pruebas cuando corresponda.