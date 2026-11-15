# TaskFlow

Proyecto de la Semana 14. Conserva el resumen y las tareas locales. El botón de nube abre una lista independiente de JSONPlaceholder; el botón de ciencias abre la práctica de isolates.

## Ejecutar

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

El proyecto declara Dart ^3.13.0. El formulario del profesor utiliza initialValue y requiere Flutter 3.35 o superior. El experimento con Isolate.run debe revisarse en Android o escritorio; no está previsto para web.

## Tareas en la nube

Se usa GET /todos?_limit=15 y POST /todos en https://jsonplaceholder.typicode.com. El servicio espera 200 y 201 respectivamente, con timeout de 10 segundos. Los registros individuales inválidos se descartan; una respuesta que no sea una lista o un JSON válido produce un error visible.

La pantalla permite reintentar, actualizar deslizando y crear mediante NuevaTareaScreen. Si falla POST, la lista anterior se conserva. Las solicitudes POST de JSONPlaceholder son simuladas: al recargar, las tareas creadas dejan de aparecer.

Las listas locales y remotas no se unen durante esta semana. No se agregó edición ni eliminación remota.

## Práctica y evidencias

Los ejercicios están en practica_sesion1/. Antes de ejecutar 1.3, registra tu predicción. La plantilla está en docs/bitacora_semana14.md. Las decisiones y comprobaciones están en docs/revision_semana14.md.

Para comprobar el servicio con internet:

```sh
dart run tool/verificar_api.dart
```

Las pruebas de flutter test utilizan respuestas controladas y no necesitan la API real.
