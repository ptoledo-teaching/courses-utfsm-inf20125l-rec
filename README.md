# REC: Depuración de recursión y backtracking

## Introducción

Una función recursiva puede ejecutar varias llamadas antes de producir un resultado. Cada llamada recibe sus propios parámetros y conserva su estado mientras espera el retorno de una llamada más profunda. Por esta razón, un valor incorrecto puede originarse en un nivel y hacerse visible solamente cuando el resultado vuelve a los niveles anteriores.

El backtracking agrega otra dificultad. Después de explorar una alternativa que no conduce a una solución, el programa debe restaurar el estado anterior antes de continuar con la alternativa siguiente. Una omisión en este proceso puede mezclar decisiones que pertenecen a recorridos diferentes y producir resultados difíciles de explicar a partir de la salida final.

Este laboratorio presenta una metodología de depuración basada en instrumentación. Las trazas permitirán observar la entrada y salida de las llamadas, representar su profundidad mediante indentación y seguir los cambios realizados al explorar y descartar alternativas. La observación se acotará mediante condiciones para evitar que el volumen de información oculte el problema investigado.

El laboratorio contiene diez test cases. Los primeros cuatro funcionan correctamente desde el comienzo y servirán como casos de control. Los seis restantes se organizan en tres pares con un nivel de orientación decreciente: primero se investigará la propagación de un resultado, luego la restauración del estado y finalmente las condiciones que determinan el término de la búsqueda.

### Prerrequisitos

- Saber navegar por directorios y ejecutar programas desde la terminal
- Saber compilar programas en C con warnings estrictos
- Saber editar código con `vim`
- Saber utilizar redirecciones y consultar códigos de salida
- Saber ejecutar y analizar una suite de test cases
- Haber trabajado previamente con instrumentación mediante `stderr`
- Tener disponibles Bash, `gcc`, `vim`, `diff` y `timeout`

### Objetivo general

- Diagnosticar y corregir problemas en funciones recursivas y algoritmos de backtracking mediante trazas de ejecución

### Objetivos específicos

- Reconocer el caso base y el avance de una función recursiva
- Distinguir el estado correspondiente a cada llamada
- Representar la profundidad de la recursión mediante indentación
- Observar cómo se propaga un resultado entre llamadas
- Seguir las decisiones de selección, exploración y retroceso
- Comprobar que el estado se restaure antes de explorar otra alternativa
- Acotar las trazas mediante condiciones locales
- Corregir problemas de manera incremental y repetir la suite completa después de cada cambio

### Estructura inicial

```text
workspace/
├── code/
│   ├── energia.c
│   └── recursion_demo.c
├── tests/
│   ├── test001.expected
│   ├── test001.in
│   ├── test002.expected
│   ├── test002.in
│   ├── ...
│   ├── test010.expected
│   └── test010.in
└── scripts/
    ├── check.sh
    └── tests-run.sh
```

El archivo `recursion_demo.c` contiene un ejemplo correcto e instrumentado que se utilizará para estudiar la forma de una traza recursiva. El trabajo principal se realizará sobre `energia.c`, que contiene el algoritmo de búsqueda y la función auxiliar que deberá completarse.

El script `tests-run.sh` ejecuta la suite y compara la salida completa de cada caso con su archivo `.expected`. Además, limita el tiempo de cada ejecución para que una recursión que no termina no deje bloqueada la actividad. El script `check.sh` permite revisar qué actividades están completas y cuáles permanecen pendientes.

## Contexto

Una estación de mantenimiento dispone de módulos de energía con distintas capacidades. Para preparar un equipo se debe seleccionar un subconjunto de esos módulos cuya energía total coincida exactamente con la cantidad requerida.

Cada módulo puede utilizarse como máximo una vez. No es obligatorio utilizar todos los módulos y puede ocurrir que no exista una combinación adecuada. Cuando hay más de una solución, el programa informa la primera que encuentra al revisar los módulos en el orden recibido.

El archivo `energia.c` recibe la siguiente información:

1. La cantidad de módulos disponibles
2. La cantidad exacta de energía requerida
3. La capacidad de cada módulo, en el orden en que debe ser considerado

Por ejemplo, la entrada:

```text
5
9
20 4 5 30 40
```

representa cinco módulos y una necesidad de nueve unidades de energía. En este caso existe una solución formada por los módulos de capacidades cuatro y cinco.

Cuando se encuentra una solución, el programa debe mostrar:

```text
Resultado: encontrado
Cantidad de modulos: <CANTIDAD>
Modulos: <CAPACIDADES SELECCIONADAS>
Energia total: <TOTAL>
```

Cuando no existe una combinación adecuada, debe mostrar:

```text
Resultado: no encontrado
```

Todos los test cases contienen entradas válidas y capacidades positivas.

### Organización de la búsqueda

La función `search_modules` recibe el índice del módulo que debe considerar, la suma acumulada y la profundidad de la llamada. El arreglo `selected` registra qué módulos pertenecen a la alternativa que se está explorando.

En cada nivel, la búsqueda considera dos posibilidades:

1. Seleccionar el módulo actual y continuar con el siguiente
2. Omitir el módulo actual y continuar con el siguiente

Si una selección conduce a la cantidad requerida, el resultado debe propagarse a todas las llamadas que se encuentran esperando. Si no conduce a una solución, el estado debe volver a representar exactamente la situación anterior a esa selección antes de explorar la omisión.

La búsqueda termina cuando encuentra la energía requerida, cuando la suma supera esa cantidad o cuando ya no quedan módulos disponibles. Dado que todas las capacidades son positivas, agregar nuevos módulos nunca puede reducir la suma.

### Lectura de las trazas

La función `trace_event` recibe un evento, la profundidad, el índice actual, la suma acumulada, la cantidad de módulos seleccionados y una condición local. Cuando la instrumentación se encuentra habilitada y la condición local se cumple, debe producir una línea como:

```text
DEBUG:     ENTRAR profundidad=2 indice=3 suma=4 seleccionadas=1
```

Los espacios entre `DEBUG:` y el evento representan la profundidad. Cada nivel agrega dos espacios. De esta manera, las líneas con la misma indentación corresponden al mismo nivel de la recursión.

Los eventos incorporados en el programa permiten reconocer los momentos principales de la búsqueda:

- `ENTRAR`: comienza una llamada
- `ELEGIR`: el módulo actual se incorpora a la alternativa
- `SOLUCION`: la suma alcanza la energía requerida
- `RETORNAR`: vuelve el resultado de una llamada más profunda
- `RETROCEDER`: una selección no permitió encontrar una solución
- `OMITIR`: comienza la exploración sin el módulo actual
- `EXCESO`: la suma supera la energía requerida
- `SIN_OPCIONES`: la llamada determina que no quedan alternativas disponibles

Las trazas se envían a `stderr`, mientras el resultado funcional permanece en `stdout`.

## Actividad

### 1. Preparar y observar los programas

#### 1.1. Inspeccionar los archivos entregados

Desde la raíz del repositorio, ingresar al directorio `workspace`. Revisar el contenido de `code`, `tests` y `scripts` sin modificarlo todavía.

En `recursion_demo.c`, ubicar la función `sum_to`, su caso base y la llamada que reduce el valor recibido. En `energia.c`, identificar `main`, `search_modules`, el arreglo `selected`, la variable `debug_enabled` y el placeholder de `trace_event` señalado mediante `TODO`.

#### 1.2. Compilar el ejemplo recursivo

El primer ejemplo se compilará mediante:

```bash
gcc -Wall -Wextra -Werror -std=c11 code/recursion_demo.c -o code/recursion_demo
```

Ejecutar `code/recursion_demo`. El resultado funcional debe indicar que la suma desde uno hasta cuatro es diez. Antes de esa línea aparecerá una traza mediante `stderr`.

#### 1.3. Interpretar la traza del ejemplo

Leer primero solamente los eventos `ENTRAR`. Comprobar que el valor disminuye en cada nivel hasta alcanzar el caso base y que la indentación aumenta al mismo tiempo.

Luego leer los eventos `RETORNAR` desde abajo hacia arriba. Para cada nivel, identificar el valor recibido, el resultado que volvió desde la llamada más profunda y el resultado construido antes de retornar.

Representar en papel las llamadas como una secuencia anidada. Marcar el momento en que cada llamada queda esperando y el momento en que puede continuar. Finalmente, cambiar temporalmente el valor inicial por seis y anticipar la cantidad de niveles antes de ejecutar nuevamente el ejemplo.

#### 1.4. Compilar el programa principal

Construir el comando necesario para compilar `code/energia.c` con `-Wall`, `-Wextra`, `-Werror` y `-std=c11`. El ejecutable debe llamarse `energia` y quedar dentro de `code`.

El programa inicial compila sin warnings. Esto confirma que sus instrucciones son válidas para el compilador, pero no demuestra que la búsqueda conserve y propague correctamente su estado.

#### 1.5. Ejecutar la suite inicial

Revisar los permisos de `scripts/tests-run.sh` y agregar permiso de ejecución para el propietario. El script recibe la ruta del ejecutable y el directorio que contiene los test cases.

Construir el comando necesario para ejecutar la suite desde `workspace`. La ejecución inicial debe mostrar cuatro pruebas exitosas y seis pruebas fallidas:

```text
PASS:  test001
PASS:  test002
PASS:  test003
PASS:  test004
FAIL:  test005
FAIL:  test006
FAIL:  test007
FAIL:  test008
FAIL:  test009
FAIL:  test010
```

Los primeros cuatro casos servirán como control. Después de cada corrección se ejecutará nuevamente la suite para comprobar que continúen entregando `PASS`.

### 2. Preparar la instrumentación

#### 2.1. Comparar las funciones auxiliares

Revisar la implementación de `trace_demo` en `recursion_demo.c` y compararla con el placeholder `trace_event` de `energia.c`. Ambas funciones reciben un control global, una condición local y una profundidad, pero la segunda debe mostrar información propia de la búsqueda de módulos.

Observar especialmente el uso de `fprintf`, `stderr` y el ancho variable utilizado para generar la indentación. No copiar la función completa sin revisar sus parámetros: los valores que debe mostrar `trace_event` son diferentes.

#### 2.2. Implementar `trace_event`

Reemplazar el contenido asociado con el marcador `TODO` por una implementación que cumpla los siguientes requisitos:

- No debe producir mensajes cuando `debug_enabled` sea cero
- No debe producir mensajes cuando la condición local sea cero
- Debe enviar cada línea mediante `stderr`
- Debe agregar dos espacios de indentación por cada nivel de profundidad
- Debe utilizar exactamente el evento y los valores recibidos
- Debe respetar el formato presentado en la sección Lectura de las trazas

Habilitar temporalmente `debug_enabled`, recompilar y ejecutar manualmente `test001`. Comprobar que la traza aparezca en `stderr` sin modificar las cuatro líneas funcionales del resultado.

Luego cambiar temporalmente la condición de una llamada a `trace_event` por cero y comprobar que solamente ese mensaje desaparezca. Restaurar la llamada y volver a dejar `debug_enabled` habilitado para las actividades siguientes.

### 3. Investigar la propagación del resultado

#### 3.1. Reproducir `test005`

Revisar `test005.in` y `test005.expected`. Calcular manualmente la primera combinación que debería encontrar la búsqueda y ejecutar solamente ese caso.

El resultado inicial indica que no se encontró una combinación. Sin embargo, la suma requerida puede alcanzarse con los primeros módulos y no es necesario omitir ninguno de ellos.

#### 3.2. Seguir el resultado entre las llamadas

Utilizar la condición local de `trace_event` para mostrar solamente llamadas con una profundidad menor o igual que dos. Ejecutar nuevamente `test005` y localizar el evento `SOLUCION`.

Desde ese evento, avanzar hacia las líneas con menor indentación. Revisar los eventos `RETORNAR` y comprobar qué resultado recibe cada llamada después de ejecutar una llamada más profunda. Identificar el primer nivel en que una solución encontrada deja de ser informada a quien realizó la llamada.

No modificar todavía las condiciones de término ni el arreglo `selected`. El objetivo de esta parte es seguir exclusivamente el valor que informa si se encontró una solución.

#### 3.3. Corregir la propagación

Corregir la instrucción que pierde el resultado observado y repetir `test005`. Luego ejecutar `test006`, cuya solución requiere un nivel adicional de recursión.

Deshabilitar temporalmente la instrumentación y ejecutar la suite completa. Desde `test001` hasta `test006` deben entregar `PASS`; los cuatro casos restantes todavía deben entregar `FAIL`.

### 4. Investigar la restauración del estado

#### 4.1. Reproducir `test007`

Revisar la entrada y el resultado esperado de `test007`. El primer módulo supera por sí solo la energía requerida, por lo que debe descartarse antes de considerar los módulos siguientes.

Ejecutar el caso con la instrumentación deshabilitada. El programa encuentra una solución, pero la cantidad de módulos y la energía total no representan solamente la combinación válida.

#### 4.2. Comparar el estado antes y después de retroceder

Habilitar la instrumentación y acotar la traza para observar los eventos correspondientes a los primeros tres índices. Comparar la cantidad de módulos seleccionados en `ELEGIR`, `RETROCEDER` y `OMITIR`.

Al comenzar la exploración de la segunda alternativa, el estado debe representar la misma selección que existía antes de incorporar el módulo descartado. Formular esa comparación para cada nivel observado y localizar el primer momento en que deja de cumplirse.

#### 4.3. Corregir la restauración

Corregir la actualización del estado respaldada por la traza. No modificar las capacidades recibidas ni la suma acumulada de la llamada.

Repetir `test007` y luego `test008`, que requiere descartar módulos en más de un nivel. Deshabilitar la instrumentación y ejecutar la suite completa. Desde `test001` hasta `test008` deben entregar `PASS`; los dos casos restantes deben continuar entregando `FAIL`.

### 5. Investigar con mayor autonomía

#### 5.1. Analizar `test009` y `test010`

Los dos casos restantes contienen una combinación válida, pero la búsqueda informa que no pudo encontrarla. Investigar ambos casos aplicando la misma metodología utilizada anteriormente:

- Reproducir un caso de manera aislada
- Determinar qué información permitiría distinguir una alternativa descartada de una alternativa que nunca fue examinada
- Elegir una condición local que muestre solamente las llamadas cercanas al término de la búsqueda
- Comparar los índices observados con la cantidad de módulos recibida
- Identificar la primera decisión que no coincide con el comportamiento descrito en el contexto

No modificar los test cases ni cambiar el orden de los módulos. Corregir solamente la causa respaldada por la traza.

#### 5.2. Comprobar la búsqueda completa

Repetir `test009` y `test010` hasta que ambos coincidan con sus resultados esperados. Luego deshabilitar la instrumentación, recompilar y ejecutar la suite completa. Los diez test cases deben entregar `PASS`.

### 6. Limpiar y comprobar el resultado

#### 6.1. Deshabilitar la instrumentación

Confirmar que `debug_enabled` tenga el valor cero. Mantener implementada `trace_event` y conservar las llamadas que permitieron investigar la búsqueda. Las condiciones locales pueden permanecer en el código.

Con entradas válidas, `stdout` debe contener solamente el resultado definido en el contexto y `stderr` no debe contener mensajes.

#### 6.2. Ejecutar la suite completa

Volver a compilar `energia.c` con las mismas opciones utilizadas inicialmente. Si aparece un warning, leerlo, corregir el problema informado y repetir la compilación.

Ejecutar `tests-run.sh` con los diez test cases. Comprobar que todos entreguen `PASS`, que el resumen informe diez pruebas exitosas y que no se produzcan errores.

### 7. Ejecutar la verificación final

#### 7.1. Preparar el script

Agregar permiso de ejecución para el propietario a `scripts/check.sh`.

#### 7.2. Revisar la actividad

Ejecutar el script desde `workspace`:

```bash
./scripts/check.sh
```

El script permite revisar las actividades consideradas e identificar cuáles se encuentran completas y cuáles permanecen pendientes.
