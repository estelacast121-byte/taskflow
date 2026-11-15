# Revisión de la Semana 14

Fecha: 15 de octubre de 2026.

## Respaldo y conservación

Antes de modificar se creó una copia completa de 960 archivos en:

C:\Users\Mauri\AppData\Local\Temp\taskflow_antes_semana14_20261015_165624

Se comprobaron los hashes de main.dart, task_notifier.dart, pubspec.yaml y pubspec.lock al crearla. La carpeta taskflow_respaldo existente no se modificó.

Al finalizar, task_notifier.dart sigue idéntico al respaldo. main.dart solo recibió dos imports y dos botones de navegación: nube y experimento de isolates. Se conservaron el resumen, las tareas iniciales, estadísticas, estilos y diálogo local.

NuevaTareaScreen se copió del profesor sin modificarlo. Se verificó que ambos archivos tienen el mismo hash SHA-256:

6946F9D972A8C79B0AD46D0801282A07A48C463FC305D3B6E0F5F3B08FA17659

No se reemplazó el proveedor local por task_provider.dart del profesor. Los archivos de referencia permanecen intactos.

## Archivos

Modificados:
- lib/main.dart: accesos a nube e isolates.
- pubspec.yaml y pubspec.lock: paquete http.
- analysis_options.yaml: unawaited_futures.
- android/app/src/main/AndroidManifest.xml: INTERNET.
- test/widget_test.dart: prueba de funciones locales.
- README.md: ejecución y alcance.

Incorporados:
- lib/modelos/tarea.dart.
- lib/datos/tareas_api.dart.
- lib/estado/tareas_remotas_provider.dart.
- lib/pantallas/tareas_remotas_screen.dart.
- lib/pantallas/nueva_tarea_screen.dart, sin cambios respecto al profesor.
- lib/validacion/validadores_tarea.dart y lib/utils/formato.dart.
- lib/practica/experimento_isolate_screen.dart.
- Los tres ejercicios de practica_sesion1/.
- test/tarea_json_test.dart, tareas_api_test.dart, tareas_remotas_provider_test.dart, tareas_remotas_screen_test.dart, task_notifier_test.dart y validadores_tarea_test.dart.
- tool/verificar_api.dart.
- docs/bitacora_semana14.md y este informe.

## Decisiones

Se mantienen dos modelos Tarea en archivos distintos. El local conserva su constructor y su inmutabilidad. El remoto utiliza el constructor requerido por el formulario del profesor. No se mezclan listas ni proveedores.

El modelo remoto acepta id entero o null, exige title de texto no vacío y normaliza sus espacios exteriores. completed ausente o null produce false; un valor de otro tipo se rechaza. fechaLimite se calcula al leer cada registro con DateTime.now() más siete días. Descripción vacía, categoría General y prioridad 2 completan los valores predeterminados. toJson envía únicamente title, completed y userId 1.

GET descarta registros individuales inválidos. Un JSON mal formado o una raíz distinta de lista producen ApiException. Si todos los registros son inválidos, el resultado es una lista vacía.

recargar utiliza AsyncLoading y AsyncValue.guard. crear no usa guard: deja el estado anterior mientras espera y propaga el error a la pantalla para mostrar un aviso, sin sustituir la lista por AsyncError. Un bloqueo interno evita operaciones de creación y recarga simultáneas. Se desactiva el reintento automático de Riverpod para que la recuperación sea explícita mediante Reintentar.

JSONPlaceholder no conserva permanentemente los POST. La recarga reemplaza la lista por los datos obtenidos del servidor. Descripción, categoría, fecha y prioridad no se envían porque no forman parte del contrato autorizado; la respuesta se interpreta con los valores predeterminados definidos.

El ejercicio 1.3 utiliza unawaited para los eventos intencionalmente independientes. El 1.6 incluye el await corregido. Los nombres de archivos del profesor se conservan mediante una excepción puntual a file_names. El modelo conserva el parámetro público prioridad por compatibilidad con el formulario.

Los cuatro escenarios de la bitácora son HTTP fallido, desconexión, timeout y JSON incorrecto, según las instrucciones autorizadas. La carpeta base hace referencia a Canvas, pero esa página no se proporcionó. Si contiene otra clasificación o formato de entrega, deberá contrastarse antes de entregar.

## Verificación realizada

- flutter pub get: terminó correctamente. Se informaron ocho dependencias con versiones más nuevas fuera de las restricciones; no se actualizaron por ese motivo.
- flutter analyze: No issues found.
- flutter test: 37 pruebas aprobadas.
- dart run tool/verificar_api.dart: GET recibió 15 tareas; POST devolvió id 201 y título Prueba Semana 14. Las comprobaciones de estado HTTP las realiza el servicio.

Las pruebas automatizadas cubren ocho casos JSON, GET y POST, HTTP 404/500, conexión, timeout de 10 segundos con reloj simulado, respuestas incorrectas, descarte individual, carga, error y reintento del proveedor, conservación ante POST fallido, creación y recarga. Las pruebas de widgets cubren carga, error, Reintentar, actualización al deslizar, formulario original, validación, POST con respuesta controlada y separación de listas. También cubren agregar, completar, desmarcar y eliminar tareas locales.

Durante la primera ejecución hubo dos fallos causados por caracteres mal codificados en las expectativas de pruebas. Se corrigieron y la ejecución final completa pasó. También se corrigieron los avisos del analizador relacionados con los archivos incorporados.

La comprobación real de API se hizo desde Dart, no desde un emulador. Las pruebas de pantalla utilizaron el entorno de widgets de Flutter. No se ha realizado una revisión visual manual en dispositivo ni se generaron capturas.

## Pendiente de revisión manual

1. Ejecutar flutter run y revisar que el resumen conserva su apariencia en el tamaño de pantalla habitual.
2. Abrir la nube, actualizar deslizando, crear con el formulario y observar el aviso. Recargar y comprobar que el POST simulado no persiste.
3. Desconectar la red, recargar y recuperar la conexión usando Reintentar.
4. Ejecutar los ejercicios y completar las predicciones y mediciones propias. Para comprobar el error original de 1.6, utilizar una copia temporal del archivo del profesor.
5. Ejecutar ambos botones de isolates en Android o escritorio y registrar tiempos y comportamiento del indicador. El código usa Isolate.run; esta práctica no está prevista para web.
6. Completar la bitácora y tomar las capturas indicadas. No se han rellenado observaciones personales ni tiempos de CPU.

## Uso de IA

Se utilizó Codex para comparar el proyecto actual con el material del profesor, preparar el flujo remoto, proponer casos JSON y pruebas, ejecutar comprobaciones y redactar esta plantilla. El formulario original se conserva. La estudiante debe revisar el código, ejecutar sus ejercicios, completar sus observaciones y poder explicar las decisiones antes de entregar. No se atribuyen a la estudiante verificaciones personales que todavía no ha realizado.

Referencias consultadas:
- Material local del profesor: README y archivos TODO de taskflow_s14_base.
- Riverpod: https://riverpod.dev/docs/concepts2/providers y https://riverpod.dev/docs/how_to/testing.
- JSONPlaceholder: https://jsonplaceholder.typicode.com/.
