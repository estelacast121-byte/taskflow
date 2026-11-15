# Semana 18: pruebas reales de reconocimiento

Estado: las cinco fotografías reales están PENDIENTES. No hay resultados medidos.

## Ejecutar en Pixel 7, Android 14 / API 34

1. Desde C:\ProyectosFlutter\taskflow, ejecutar `flutter devices` y verificar emulator-5554.
2. Si ya existe un `flutter run` activo de este proyecto, usar `r` en esa terminal para recargar (o `R` para reiniciar). En caso contrario, ejecutar `flutter run -d emulator-5554`.
3. Arrastrar las cinco imágenes JPG/PNG al emulador. Si no aparecen en el selector, usar Archivos/Downloads desde el selector de galería. La cámara requiere una cámara virtual configurada en el AVD; si no está disponible, usar galería.
4. Pulsar «Escanear tarea» encima del resumen. Elegir «Seleccionar de la galería» o «Tomar fotografía». Esperar el indicador de procesamiento.
5. Copiar el texto reconocido manteniéndolo pulsado y registrarlo SIN corregir en esta bitácora. Registrar también el texto vacío o cualquier mensaje de error.
6. Pulsar «Revisar propuesta de tarea». El texto original completo permanece disponible. La primera línea propone el título y el texto completo propone la descripción. Ajustar el título a 3–60 caracteres y la descripción a un máximo de 200; el original no se recorta. Elegir fecha y revisar prioridad y categoría: no se infieren del OCR.
7. Pulsar «Guardar tarea»: valida y añade al listado local mediante el provider existente. Volver atrás o cancelar no guarda. El reconocimiento y la propuesta por sí solos nunca crean una tarea.
8. Comprobar también completar/eliminar tareas, «Agregar tarea», navegación a tareas remotas y experimento de isolates.

El OCR usa ML Kit latino en el dispositivo, sin subir fotos. Las fotos permanecen en la caché/selector del sistema; esta función no crea un archivo permanente. Si Android cierra la actividad mientras se elige una foto, volver a abrir «Escanear tarea» para recuperar la selección pendiente y revisarla. Las tareas locales conservan el almacenamiento en memoria del proyecto: se pierden al reiniciar la aplicación. Copiar los resultados a esta bitácora antes de cerrar.

## Criterio de error

Antes de escanear, transcribir literalmente el texto esperado de cada fotografía. Para comparar, sustituir saltos de línea y grupos de espacios por un solo espacio y quitar espacios al principio/final. Conservar mayúsculas, tildes, puntuación y orden. Una fotografía tiene error si ambos textos normalizados difieren, si no se detecta texto esperado o si falla el procesamiento. Cancelar el selector no cuenta como prueba realizada.

Tasa sobre las cinco fotografías = (fotografías con error / 5) × 100 %. Cada foto aporta 20 puntos porcentuales. No calcular la tasa final hasta completar las cinco. Es una tasa de imágenes con discrepancias, NO una tasa por carácter ni por palabra.

| Foto | Tipo | Texto esperado | Texto reconocido | ¿Error? | Descripción del error | Resultado |
|---|---|---|---|---|---|---|
| 1 | Nota escrita a mano | Pendiente | Pendiente | Pendiente | Pendiente | No ejecutada |
| 2 | Pizarra | Pendiente | Pendiente | Pendiente | Pendiente | No ejecutada |
| 3 | Página impresa | Pendiente | Pendiente | Pendiente | Pendiente | No ejecutada |
| 4 | Captura de pantalla | Pendiente | Pendiente | Pendiente | Pendiente | No ejecutada |
| 5 | Poca iluminación o inclinada | Pendiente | Pendiente | Pendiente | Pendiente | No ejecutada |

Para textos largos, añadir debajo una sección por foto con texto esperado y reconocido completos y referenciarla desde la tabla. Registrar fecha, nombre del archivo, dispositivo/API y condiciones de luz/inclinación. Resultado: «Sin discrepancias», «Con discrepancias» o «Fallo de procesamiento».

Fotografías ejecutadas: 0/5. Fotografías con error: pendiente. Tasa final: pendiente.

ML Kit puede equivocarse, especialmente con manuscritos y fotos deficientes. Por eso propone información y exige revisión, validación y confirmación humana. No hay guardado automático ni participación de foro generada.

## Configuración

Se conservan dependencias y configuración Android existentes. image_picker usa Android Photo Picker en Android 13+ y la app de cámara del sistema; no requiere añadir permisos de almacenamiento ni CAMERA para este flujo. Referencia: https://pub.dev/packages/image_picker. El plugin de OCR es móvil: Android/iOS, no Web/Windows. La entrega se valida para Android; iOS requiere configurar permisos de cámara/fototeca y comprobar los requisitos nativos antes de distribuirlo.

## Verificación automatizada de esta implementación

- `flutter pub get`: correcto, sin añadir dependencias ni actualizar restricciones.
- `flutter test`: 53 pruebas aprobadas, incluidas 5 nuevas pruebas de escaneo con un reconocedor falso y la regresión de agregar/completar/eliminar tareas locales.
- Las pruebas del escaneo cubren revisión/cancelación sin guardar, validación de fecha, edición y confirmación, imagen sin texto, cancelación del selector, error/reintento y cierre seguro durante el procesamiento.
- Se detectó el emulador emulator-5554 con Android 14/API 34 y una sesión de `flutter run` activa para TaskFlow. No se inició otra instancia.
- Estas pruebas no miden la precisión real del OCR. Las cinco fotografías y la comprobación visual en el emulador siguen pendientes.
- `flutter analyze`: correcto, «No issues found!» en la comprobación final.
- `flutter build apk --debug`: correcto; APK generado en `build/app/outputs/flutter-apk/app-debug.apk`. No se instaló sobre la sesión activa.
