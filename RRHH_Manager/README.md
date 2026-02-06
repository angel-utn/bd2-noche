# Base de Datos II — UTN RRHH Manager
**Actividad Práctica: Triggers, Stored Procedures y Vistas (SQL Server)**

> Universidad Tecnológica Nacional — Facultad Regional General Pacheco  
> Base de Datos II

---

## Descripción general

Este documento describe una actividad práctica sobre la base de datos **UTN_RRHH_Manager**, orientada a aplicar y consolidar conocimientos sobre:

- **Vistas (VIEW)**
- **Procedimientos almacenados (Stored Procedures)**
- **Triggers** con lógica de negocio (en particular, triggers complejos)

El objetivo es implementar los objetos de base de datos necesarios para que la aplicación provista funcione completamente.

---

## Requisitos previos

- SQL Server con la base de datos proporcionada
- Runtime de .NET Core 8

**Recursos**
- Script de base de datos y binarios de la aplicación (provistos en el material de la actividad)

---

## 1. Configuración inicial

### 1.1 Restauración de la base de datos

1. Localizar el archivo `Db.sql` en la carpeta de recursos del proyecto.
2. Abrir el archivo en SQL Server Management Studio (SSMS) o el cliente SQL que prefieras.
3. Ejecutar el script completo para crear la base de datos `UTN_RRHH_Manager`.
4. Verificar que se hayan creado correctamente las tablas principales:
   - `Empleados`
   - `Feriados`
   - `SolicitudesDiasLibres`

### 1.2 Configuración de la aplicación

La aplicación .NET lee la cadena de conexión desde el archivo `UTN.RRHH.Manager.dll.config`.

Ejemplo de configuración (`config`):

```xml
<!-- Agregar dentro de <configuration> -->
<connectionStrings>

  <!-- Autenticación de Windows (Integrated Security) -->
  <add name="DB"
       connectionString="Data Source=YOUR_SERVER_NAME;
                         Initial Catalog=UTN_RRHH_Manager;
                         Integrated Security=True;
                         TrustServerCertificate=True"
       providerName="System.Data.SqlClient" />

  <!-- Autenticación SQL Server (User ID / Password) -->
  <!--
  <add name="DB"
       connectionString="Data Source=YOUR_SERVER_NAME;
                         Initial Catalog=UTN_RRHH_Manager;
                         User ID=miUsuario;
                         Password=miPassword;
                         TrustServerCertificate=True"
       providerName="System.Data.SqlClient" />
  -->
</connectionStrings>
```

Notas:
- Reemplazar `YOUR_SERVER_NAME` por el nombre del servidor. Para instancias locales, podés usar `localhost`, `.`, o `.\SQLEXPRESS`.
- `TrustServerCertificate=True` es útil en desarrollo local para evitar problemas con certificados SSL.
- Descomentá la opción de autenticación que corresponda a tu entorno.

Para verificar la conexión: ejecutar `UTN.RRHH.Manager.exe` y revisar la barra de estado inferior.

---

## 2. Estructura de la base de datos

La base `UTN_RRHH_Manager` se compone de tres tablas principales.

### 2.1 Tabla `Empleados`

Almacena información básica de cada empleado y su saldo de días libres.

| Columna     | Tipo          | Restricción               | Descripción              |
|------------|---------------|---------------------------|--------------------------|
| idempleado | INT           | PK, IDENTITY(1,1)         | Identificador único      |
| apellidos  | VARCHAR(100)  | NOT NULL                  | Apellidos del empleado   |
| nombres    | VARCHAR(100)  | NOT NULL                  | Nombres del empleado     |
| diaslibres | INT           | NOT NULL, DEFAULT 0       | Saldo de días disponibles|

> `diaslibres` representa el stock de días libres que el empleado puede solicitar. Se decrementa automáticamente cuando se aprueba una solicitud.

### 2.2 Tabla `Feriados`

Calendario de feriados utilizado para consultas y validaciones.

| Columna     | Tipo         | Restricción | Descripción            |
|------------|--------------|-------------|------------------------|
| fecha      | DATE         | PK          | Fecha del feriado      |
| descripcion| VARCHAR(200) | NOT NULL    | Descripción del feriado|

### 2.3 Tabla `SolicitudesDiasLibres`

Registra solicitudes de días libres, su estado, y motivo de rechazo.

| Columna       | Tipo          | Restricción        | Descripción             |
|--------------|---------------|--------------------|-------------------------|
| idsolicitud  | INT           | PK, IDENTITY(1,1)  | Identificador único     |
| idempleado   | INT           | FK, NOT NULL       | Referencia al empleado  |
| fechadialibre| DATE          | NOT NULL           | Fecha solicitada        |
| aprobada     | BIT           | DEFAULT 0          | Estado de aprobación    |
| razonrechazo | VARCHAR(MAX)  | NULL               | Motivo del rechazo      |

La tabla incluye una clave foránea hacia `Empleados` mediante la constraint `FK_Solicitudes_Empleados`.

---

## 3. Vistas (VIEW)

Las vistas simplifican consultas desde la aplicación y exponen columnas calculadas o agregadas.

### 3.1 Vista `VW_Feriados`

Debe devolver los feriados registrados, junto con los días faltantes para cada uno.

**Columnas requeridas (exactas):**
- `fecha` (DATE)
- `descripcion` (VARCHAR(200))
- `diasparaferiado` (INT): diferencia entre la fecha del feriado y la fecha actual.

La aplicación consume esta vista en el listado de feriados y en el dashboard, ordenando ascendente por fecha.

### 3.2 Vista `VW_TopEmpleados`

Listado consolidado de empleados con nombre completo y saldo de días.

**Columnas requeridas (exactas):**
- `nombrecompleto` (VARCHAR): `"Apellido, Nombre"`
- `diaslibres` (INT)

La aplicación ordena descendente por `diaslibres` y la usa para el ranking en el dashboard.

### 3.3 Vista `VW_Ausencias`

Unifica feriados + solicitudes aprobadas, para visualización del calendario de ausencias.

**Columnas requeridas (exactas):**
- `tipo` (VARCHAR(10)): `'Feriado'` o `'Solicitud'`
- `fecha` (DATE)
- `descripcion` (VARCHAR(150)):
  - Feriados: descripción del feriado
  - Solicitudes: `"Apellido, Nombre"` del empleado solicitante

**Importante:** considerar únicamente solicitudes aprobadas (`aprobada = 1`).  
Sugerencia: usar `UNION ALL` verificando tipos compatibles.

---

## 4. Procedimientos almacenados (Stored Procedures)

Encapsulan lógica de negocio y operaciones CRUD.

### 4.1 Procedimiento `SP_AltaEmpleado`

Registra un nuevo empleado.

**Parámetros requeridos (exactos):**
- `@apellidos` (VARCHAR(100))
- `@nombres` (VARCHAR(100))
- `@diaslibres` (INT) — por defecto: 0

Requisitos:
- Inserta un registro en `Empleados`.
- **No** debe retornar conjuntos de resultados con `SELECT` (la app usa `ExecuteNonQuery`).

**Manejo de errores:**
- Si necesitás controlar mensajes de error, usar `RAISERROR` con textos descriptivos (la app muestra el `Message` de la excepción).

### 4.2 Procedimiento `SP_AltaFeriado`

Registra un nuevo feriado.

**Parámetros requeridos (exactos):**
- `@fecha` (DATE)
- `@descripcion` (VARCHAR(200))

Requisitos:
- Inserta en `Feriados`.
- Implementar validaciones de negocio (por ejemplo, no permitir fechas pasadas).

### 4.3 Procedimiento `SP_EstadisticasGenerales`

Calcula métricas agregadas para el dashboard.

- No recibe parámetros.
- Retorna mediante `SELECT` una única fila con:

| Columna               | Tipo      | Descripción |
|----------------------|-----------|-------------|
| TotalSolicitudes     | INT       | Total de solicitudes en los últimos 365 días |
| PorcentajeAprobacion | DECIMAL   | Proporción aprobadas/total (decimal) |
| DiasAcumulados       | INT       | Suma de `diaslibres` de todos los empleados |

**Nota:** si no hay solicitudes en el período, manejar división por cero retornando `0` o `NULL` según corresponda.

---

## 5. Trigger de validación de solicitudes

### 5.1 Descripción general

Trigger `AFTER INSERT` sobre `SolicitudesDiasLibres`.  
Evalúa automáticamente cada solicitud según reglas de negocio y decide si se aprueba o se rechaza, registrando el motivo.

**Reglas de negocio (evaluar en orden):**
1. **Stock de días**: el empleado debe tener saldo (`diaslibres > 0`).
2. **Consecutivos**: el empleado no puede tener un día libre aprobado el día inmediatamente anterior a la fecha solicitada.
3. **Feriados**: el día inmediatamente anterior a la fecha solicitada no puede ser un feriado (evitar extensión artificial de fines de semana largos).
4. (El documento indica “cuatro condiciones”; implementar las indicadas y respetar el orden.)

**Validación de fechas:**
Usar funciones como `DATEADD(DAY, -1, @FechaSolicitada)` y consultar las tablas correspondientes.

**Orden de evaluación (crítico):**
La primera condición que falle debe detener la evaluación y generar el rechazo con el motivo específico.

### 5.2 Escenario A: solicitud aprobada

Acciones:
1. Actualizar la fila insertada: `aprobada = 1`
2. Descontar 1 día de `Empleados.diaslibres` del empleado
3. `razonrechazo` queda `NULL`

### 5.3 Escenario B: solicitud rechazada

Acciones:
1. Actualizar la fila insertada: `aprobada = 0`
2. Setear `razonrechazo` con un mensaje descriptivo
3. No descontar stock

Ejemplos de mensajes:
- `Rechazada: no posee días libres disponibles.`
- `Rechazada: no puede solicitar días consecutivos (día anterior o posterior ya aprobado).`
- `Rechazada: no puede ser consecutivo al feriado Carnaval - 17/02/2026.`

---

## 6. Verificación y pruebas

### 6.1 Pruebas de vistas

```sql
-- Verificar VW_Feriados
SELECT * FROM VW_Feriados;

-- Verificar VW_TopEmpleados
SELECT * FROM VW_TopEmpleados;

-- Verificar VW_Ausencias
SELECT * FROM VW_Ausencias;
```

### 6.2 Pruebas de procedimientos almacenados

```sql
-- Probar alta de empleado
EXEC SP_AltaEmpleado
  @apellidos = 'González',
  @nombres   = 'María Laura',
  @diaslibres = 10;

-- Probar alta de feriado
EXEC SP_AltaFeriado
  @fecha = '2026-05-01',
  @descripcion = 'Día del Trabajador';

-- Probar estadísticas generales
EXEC SP_EstadisticasGenerales;
```

### 6.3 Pruebas del trigger

```sql
-- Caso 1: Empleado sin días disponibles
INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre)
VALUES (1, '2026-03-15');

-- Verificar que se rechazó y el motivo
SELECT * FROM SolicitudesDiasLibres
WHERE idsolicitud = SCOPE_IDENTITY();

-- Caso 2: Solicitud de día consecutivo a feriado
INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre)
VALUES (2, '2026-02-18'); -- Día siguiente a Carnaval

-- Caso 3: Solicitud válida que debe aprobarse
INSERT INTO SolicitudesDiasLibres (idempleado, fechadialibre)
VALUES (3, '2026-04-10');

-- Verificar que se aprobó y se descontó el día
SELECT e.nombres, e.apellidos, e.diaslibres,
       s.aprobada, s.razonrechazo
FROM Empleados e
INNER JOIN SolicitudesDiasLibres s ON e.idempleado = s.idempleado
WHERE s.idsolicitud = SCOPE_IDENTITY();
```

### 6.4 Integración con la aplicación

1. **Empleados**: alta y verificación de visualización.
2. **Feriados**: alta y verificación de cálculo de días.
3. **Solicitudes**: creación y verificación de aprobación/rechazo con motivo.
4. **Dashboard**: verificación de métricas y consistencia de vistas.

---

## 7. Conclusión

La actividad integra conceptos de programación en SQL Server combinando vistas, procedimientos almacenados y triggers para automatizar reglas de negocio, garantizar integridad de datos y facilitar el mantenimiento.

