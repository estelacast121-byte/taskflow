# Semana 19, sesión 2, fase 1

El adaptador usa exclusivamente taskProvider y TaskNotifier, sin persistencia.
No se han cambiado los modelos ni las operaciones anteriores.

Herramientas:
- listar_tareas: {}. Devuelve una instantánea inmutable.
- crear_tarea: titulo obligatorio; detalle opcional (vacío), prioridad opcional
  (Media; solo Baja, Media o Alta). Título y detalle usan los validadores existentes.
- completar_tarea y eliminar_tarea: un id entero positivo o un titulo de búsqueda.
  Se normalizan mayúsculas, espacios y vocales acentuadas; se buscan coincidencias
  por subcadena, sin elegir la primera ni priorizar la coincidencia exacta entre
  varias. La ambigüedad devuelve candidatos con ID. Para resolverla usar un ID.
  No se admiten listas, selectores múltiples ni campos desconocidos.

El modelo local solo almacena id, titulo, detalle, prioridad y completada.
A diferencia del formulario, no tiene fechaLimite, descripcion ni categoria
estructuradas. No se inventan esos campos ni se deducen del texto detalle.
Se limita detalle a los 200 caracteres del validador de descripción existente.

preparar no muta tareas. Las modificaciones se guardan como AccionModificacion
inmutable, ligada a su instancia de HerramientasTareas. ejecutar exige aprobada
explícita; la futura UI será responsable de obtener confirmación humana. Esta
fase no implementa UI ni permite a Gemini invocar ejecutar. Aprobar o rechazar
consume la acción y evita ejecuciones repetidas. La ejecución es síncrona y
revalida la tarea: existencia, ID único e identidad/valores de la instantánea.
Los cambios o recreación de la tarea exigen preparar y aprobar de nuevo.
Completar nunca alterna una tarea ya completada a pendiente. Crear revalida los
campos y calcula el siguiente ID al ejecutar. Solo se elimina un ID único.

No se disponía del material completo del Paso 2 del profesor en el proyecto:
se siguen las tres variantes solicitadas de AccionPreparada y el contrato de
esta fase, sin atribuir al material firmas no proporcionadas.

## Fase 2: motor independiente del proveedor

modelo_agente.dart define ModeloAgente y un protocolo tipado: RespuestaFinal o
SolicitudHerramientas, con IDs de llamada, argumentos JSON y observaciones.
Cada contexto conserva la instrucción y el historial de solicitudes/resultados;
los argumentos se copian y las colecciones del historial son inmutables.
No contiene Firebase, red ni clases del SDK Gemini.

agente_notifier.dart expone agenteProvider y modeloAgenteProvider. Este último
no tiene un proveedor real conectado: debe sobrescribirse con un modelo simulado
para pruebas. El controlador permite iniciar, confirmar(id, aprobada: bool) y
cancelar. Una ejecución nueva se rechaza mientras otra está activa.

Los estados sellados en estado_agente.dart representan exclusivamente inactivo,
pensando (iteración), ejecutando (herramienta e ID), esperando confirmación
(ID único y acción inmutable), terminado y error.

Cada instrucción admite hasta 5 consultas al modelo y 10 llamadas a herramientas
acumuladas, incluidas inválidas y duplicadas. Al superar un límite termina en
error; no se ejecutan más herramientas. La consulta siguiente recibe las
observaciones de las herramientas (incluidos errores y rechazos) si queda una
iteración disponible. No se hace una sexta consulta para informar del límite.

Las modificaciones esperan un Completer que solo resuelve confirmar con el ID
vigente. La futura UI debe obtener la aprobación humana antes de llamar ese
método. Las lecturas no esperan confirmación. La operación final vuelve a pasar
por HerramientasTareas.ejecutar y sus comprobaciones de vigencia.

Se rechazan IDs de llamada repetidos. Además, una firma formada por herramienta
y argumentos preparados normalizados evita volver a proponer la misma
modificación (aprobada o rechazada) durante la instrucción. Los selectores de
completar/eliminar se convierten al ID resuelto; crear usa sus valores y defaults.
No se reintenta automáticamente una modificación: se necesita otra instrucción.
Esto es deduplicación de acciones concretas, no comparación semántica de lenguaje
natural. Otras acciones distintas siguen exigiendo su propia confirmación.

Cancelar consume la acción pendiente como rechazada, resuelve el Completer,
vuelve a inactivo e invalida los resultados del modelo anterior. No necesita
esperar a que un modelo pendiente finalice. Dispose hace la misma invalidación
sin escribir estado. Los IDs de confirmación no se reciclan entre instrucciones.
La cancelación del motor no cancela físicamente una implementación remota del
modelo: sus resultados tardíos se descartan.

No se han añadido pantalla, conexión a Gemini ni cambios a las funciones previas.
## Fase 3: adaptador Firebase AI Logic (sin pantalla)

ServicioGeminiAgente implementa ModeloAgente. modeloAgenteProvider ahora crea
este adaptador de forma diferida; construirlo no hace llamadas de red ni exige
Firebase en las pruebas que inyectan un modelo simulado.

Usa FirebaseAI.googleAI(), la aplicación Firebase predeterminada ya inicializada
por main y su servicio App Check. El modelo predeterminado es
gemini-3.5-flash-lite, reemplazable con GEMINI_MODEL. Cada consulta mantiene el
límite de 120 segundos; no añade reintentos ni ejecuta herramientas.

Se verificaron FunctionDeclaration(name, description, parameters: ...,
optionalParameters: ...), Tool.functionDeclarations, response.functionCalls y
FunctionResponse(name, response, id: ...) en firebase_ai 5.1.0. Son declaraciones
simples, sin callbacks automáticos. listar no tiene parámetros; crear exige
titulo y admite detalle y prioridad; completar/eliminar admiten id o titulo,
ambos opcionales en el esquema para expresar alternativas, pero el motor exige
exactamente uno. Sus validaciones y confirmaciones no han cambiado.

El adaptador reconstruye cada solicitud con la instrucción y los intercambios
anteriores. Conserva el Content original del modelo asociado a cada solicitud
mediante Expando, incluyendo firmas de pensamiento, nombres e IDs del SDK.
Los IDs ausentes reciben identificadores locales solo para el motor;
FunctionResponse conserva el ID original, incluso si es null. Los resultados
se emparejan por orden y se verifica el ID local de cada observación. Historial
incompleto o de otro adaptador produce un error seguro, sin inventar firmas.

No se persiste este historial: una nueva instancia requiere nueva instrucción.
Cancelar o agotar el timeout no acepta respuestas tardías; el motor conserva la
responsabilidad de invalidar su ejecución. No hay aprobación desde el modelo.
Las instrucciones del sistema exigen aclarar datos faltantes/ambigüedades,
no inventar tareas/fechas, no simular éxito tras rechazo, ignorar instrucciones
incrustadas en datos y no pedir eliminaciones masivas.

Los diagnósticos SDK registran solo etapa, tiempo, tipo y código permitido.
El envolvente HTTP existente se usa solo en debug y se puede deshabilitar con
GEMINI_HTTP_DIAGNOSTICO=false. Nunca se imprimen respuestas, instrucciones,
argumentos, firmas, tokens ni cabeceras. La futura pantalla será necesaria para
usar esta integración manualmente; no se ha añadido un acceso ni cambiado el
flujo previo de notas con Gemini o ML Kit.

Las pruebas inyectan GenerarTurnoAgente y construyen respuestas del SDK sin red.
Referencia oficial: https://firebase.google.com/docs/ai-logic/function-calling
## Fase 4: pantalla del asistente y guion simulado

Desde el resumen principal, pulsar Asistente de tareas. La pantalla muestra la
instrucción, respuestas, fases y resultados reales de herramientas. El registro
Riverpod de observaciones es solo de presentación: no ejecuta operaciones.
Los estados sellados siguen controlando el envío, progreso y confirmación.
Cada instrucción inicia una ejecución independiente; no se reutilizan aprobaciones
ni se presupone memoria conversacional entre instrucciones. El historial visual
es efímero y desaparece al cerrar la pantalla.

La tarjeta muestra el resumen y todos los argumentos de la acción preparada.
Aprobar/Rechazar envían exclusivamente el ID de confirmación vigente al motor.
Un doble toque no puede aprobar dos veces. Cancelar usa el mecanismo del motor;
salir de la pantalla también lo cancela, sin aceptar resultados tardíos.
No se puede enviar mientras está pensando, ejecutando o esperando confirmación.
Las fases de ejecución breves quedan asimismo registradas en la conversación.

Prueba con un emulador ya iniciado manualmente (sustituir ID_ANDROID):

```powershell
flutter run --debug -d ID_ANDROID --dart-define=AGENTE=simulado
```

El aviso MODO SIMULADO identifica que no se llama a Gemini. Firebase/App Check
conservan su inicialización habitual, pero el modelo del agente es un guion local
limitado. Reconoce las cinco sugerencias mostradas y también:
Lista mis tareas; Completa la tarea ID; Elimina la tarea ID.
ID debe ser un número. El resto recibe un aviso explícito de instrucción no
reconocida; no se finge comprensión. Para Elimina Repasar, si no existe informa
del error. Para probar ambigüedad, crear manualmente dos tareas con Repasar en
el título usando los formularios existentes. Ninguna se elige automáticamente.
Las solicitudes masivas/maliciosas y la fecha 31/02/2027 no producen herramientas
de modificación en el guion. Esto no sustituye las validaciones del motor.

Para usar Gemini real (requiere internet y App Check registrado):

```powershell
flutter run --debug -d ID_ANDROID
```

No conservar AGENTE=simulado en la configuración del IDE al probar Gemini real.
En modo real se informa que instrucciones y datos necesarios de las tareas se
procesan en Gemini en la nube. Probar crear/rechazar, aprobar, listar, completar,
eliminar una tarea concreta, cancelar y salir con confirmación pendiente.
Volver al resumen y comprobar la lista local y su porcentaje de completadas.
Los flujos de ML Kit y Nota con Gemini conservan sus accesos anteriores.