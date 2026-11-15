# Ocho pruebas de JSON incorrecto

Verificación realizada el 16 de octubre de 2026. Se revisaron test/tarea_json_test.dart, test/tareas_api_test.dart y el material del profesor. El README solicita validar fromJson con casos propuestos con apoyo de IA y ejecutados. Los casos existentes se conservaron; esta actividad agrega ocho casos exclusivamente inválidos en test/json_incorrecto_test.dart.

## Resultados para la bitácora

| Caso | Dato modificado | Resultado esperado | Resultado real | Manejo correcto |
|---|---|---|---|---|
| 1 | Se omitió title | FormatException; GET descarta el registro y conserva el válido | Se lanzó FormatException y GET devolvió solo la tarea válida | Sí |
| 2 | title contiene solo espacios | FormatException; GET descarta el registro y conserva el válido | Se lanzó FormatException y GET devolvió solo la tarea válida | Sí |
| 3 | title es el número 8 | FormatException; GET descarta el registro y conserva el válido | Se lanzó FormatException y GET devolvió solo la tarea válida | Sí |
| 4 | id es el texto "1" | FormatException; GET descarta el registro y conserva el válido | Se lanzó FormatException y GET devolvió solo la tarea válida | Sí |
| 5 | completed es el texto "false" | FormatException; GET descarta el registro y conserva el válido | Se lanzó FormatException y GET devolvió solo la tarea válida | Sí |
| 6 | Respuesta GET truncada: [{"title": | ApiException: El servidor devolvió un JSON incorrecto. | Se obtuvo ApiException con ese mensaje exacto | Sí |
| 7 | GET devuelve un objeto en lugar de una lista | ApiException: Se esperaba una lista de tareas. | Se obtuvo ApiException con ese mensaje exacto | Sí |
| 8 | POST devuelve 201, pero title es null | ApiException: La tarea recibida tiene datos incorrectos. | Se obtuvo ApiException con ese mensaje exacto | Sí |

Los ocho casos pasaron. En los primeros cinco se comprobó tanto el rechazo directo del modelo como el descarte individual en GET. Los otros tres comprobaron el tipo y mensaje exacto del error del servicio. Los casos 1 a 5 y 8 son datos JSON sintácticamente válidos pero incompatibles con el modelo; el 6 es JSON mal formado y el 7 tiene estructura incorrecta para GET.

Estas son pruebas automatizadas de modelo y servicio con MockClient. No alteran JSONPlaceholder ni las rutas de producción y no requieren desconectar Internet. La columna de manejo correcto describe lo comprobado en esas capas; no representa ocho observaciones manuales de pantalla.

## Captura

Desde C:\ProyectosFlutter\taskflow:

```powershell
flutter test test/json_incorrecto_test.dart --reporter expanded
```

Capturar los ocho nombres de pruebas y la línea final All tests passed. Guardar la imagen con el siguiente número libre de Evidencias_Semana_14, por ejemplo 13_json_incorrecto.png si el 12 ya corresponde a Con isolate.

La salida real registrada está en docs/resultados_json_incorrecto.txt. La captura debe tomarla la estudiante al ejecutar el comando; no se creó una imagen artificial.

## Cambios y apoyo de IA

Se añadió únicamente el archivo de pruebas y esta documentación con su registro de salida. No se modificaron el diseño, las tareas locales, el formulario ni el código del servicio/modelo. Codex propuso los casos y ejecutó sus comprobaciones; queda pendiente la ejecución y captura personal de la estudiante. No se preparó la entrega final.

## Verificación general posterior

- flutter analyze: No issues found; 4,9 segundos.
- flutter test: 48 pruebas aprobadas, incluidas las ocho nuevas; ejecución completa de aproximadamente 22 segundos.
