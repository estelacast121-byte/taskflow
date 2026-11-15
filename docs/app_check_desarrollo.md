# App Check en Android durante el desarrollo

TaskFlow activa App Check después de Firebase y antes de runApp, solo en
Android y en modo debug. No configura un proveedor para profile o release.
Antes de distribuir la aplicación habrá que configurar un proveedor de producción.

La dependencia firebase_app_check 0.5.1 usa
`providerAndroid: const AndroidDebugProvider()`; esta es la API equivalente a
`androidProvider: AndroidProvider.debug` de versiones anteriores.
firebase_ai 5.1.0 ya dependía de esta misma versión de App Check.

## Validar desde PowerShell

```powershell
Set-Location C:\ProyectosFlutter\taskflow
flutter pub get --offline
flutter analyze
flutter test
```

El paquete ya está en la caché local. Si pub informa que falta algún paquete,
ejecutar `flutter pub get` con conexión. No se necesita volver a configurar Firebase.

## Obtener y registrar el secreto de depuración

Cuando decidas probar en un emulador que hayas iniciado manualmente:

1. Ejecuta `flutter devices` y luego `flutter run --debug -d <ID_ANDROID>`
   sustituyendo el marcador por el identificador Android mostrado.
2. Revisa la consola de ejecución o Logcat y busca `DebugAppCheckProvider`
   y el mensaje `Enter this debug secret into the allow list`.
3. Si aún no aparece, detén la ejecución con un breakpoint después de `activate`
   y evalúa `FirebaseAppCheck.instance.getToken(true)` en la consola de depuración.
   La primera solicitud puede fallar antes de registrar el secreto: es esperable.
   No imprimas ni copies el token App Check devuelto por getToken; el secreto que
   se registra es el que muestra el SDK nativo en el mensaje de Logcat.
4. En Firebase Console, proyecto taskflow-nancy, abre App Check > Apps.
   En la aplicación Android com.example.taskflow, abre el menú de tres puntos >
   Administrar tokens de depuración (Manage debug tokens). Agrega el secreto
   con un nombre que identifique tu emulador de desarrollo.
5. Reinicia la aplicación y repite la solicitud si deseas comprobar el intercambio.

No es necesario completar el registro de Play Integrity para usar el proveedor
de depuración. Si la consola tampoco permite administrar tokens de depuración,
ese bloqueo de consola debe resolverse antes de validar el intercambio.

Mantén el secreto privado: no lo agregues a código, archivos, capturas, informes
de pruebas ni Git. Si se expone, elimínalo desde la consola. Borrar los datos de la
app o recrear el emulador puede requerir registrar otro secreto.

No activar enforcement: la activación del SDK cliente no modifica ese ajuste.
El estado actual en Firebase Console debe revisarse por separado, especialmente
para Firebase AI Logic; esta configuración local no lo habilita ni lo deshabilita.

Referencia: https://firebase.google.com/docs/app-check/flutter/debug-provider
