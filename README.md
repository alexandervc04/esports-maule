---------------DATABASE---------------

## PASO 1: Encender servicios de Oracle XE en Windows
Encender servicios de Oracle XE en Windows
*(Solo si aparece el error `ORA-12541: No hay ningún listener`)*

1. Presionar `Win + R`, escribir **`services.msc`** y presionar **Enter**.
2. Buscar en la lista los siguientes dos servicios, hacer clic derecho sobre cada uno y presionar **Iniciar** (deben quedar en estado *En ejecución*):
   - **`OracleOraDB21Home1TNSListener`**
   - **`OracleServiceXE`**

---

## PASO 2: Crear el usuario `ESPORTS_DB` en SQL Developer
*(Se realiza una única vez en cada computador)*

1. Abrir **Oracle SQL Developer** y hacer clic en el botón verde **`+`** (*Nueva conexión*).
2. Configurar la conexión de administrador con estos datos:
   - **Name:** `SYSTEM_XE`
   - **Usuario:** `SYSTEM`
   - **Contraseña:** *(la clave definida al instalar Oracle XE)*
   - **Nombre del Host:** `localhost`
   - **Puerto:** `1521`
   - **Nombre del Servicio:** *(marcar el círculo de Nombre del Servicio, NO SID)* -> **`XEPDB1`**
3. Presionar **Probar** (debe indicar *Estado: Correcto*) y luego **Conectar**.
4. En la hoja de trabajo SQL que se abre, pegar y ejecutar (`F5`) estas dos líneas:
   ```sql
   CREATE USER ESPORTS_DB IDENTIFIED BY esports2026;
   GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO ESPORTS_DB;
   ```
---
   
## PASO 3: Conectar `ESPORTS_DB` y cargar toda la Base de Datos

1. En **Oracle SQL Developer**, hacer clic nuevamente en el botón verde **`+`** (*Nueva conexión*) y rellenar los campos exactos:
   - **Name:** `Proyecto_Esports`
   - **Usuario:** `ESPORTS_DB`
   - **Contraseña:** `esports2026`
   - **Tipo de Conexión:** `Básico`
   - **Nombre del Host:** `localhost`
   - **Puerto:** `1521`
   - **Nombre del Servicio:** *(marcar el círculo de Nombre del Servicio, NO SID)* -> **`XEPDB1`**
2. Presionar **Probar** (debe mostrar *Estado: Correcto*), luego **Guardar** y finalmente **Conectar**.
3. En el menú superior de SQL Developer, ir a **Archivo -> Abrir**, buscar la carpeta descargada del repositorio y seleccionar **`database/main.sql`**.
4. Presionar **`F5`** (*Ejecutar script*) o el ícono de la hoja con flecha verde y esperar a que termine la ejecución en la pestaña *Salida de Script*.
   - **Verificación:** Al desplegar la conexión `Proyecto_Esports` en el panel izquierdo deben aparecer **19 Tablas**, **19 Secuencias**, **3 Funciones**, **3 Disparadores (Triggers)** y **38 Procedimientos** con el prefijo `AV_JP_RM_BE_`, además de los datos iniciales y registros de auditoría cargados.

---



---------------DRIVER---------------

-Instalar XAMPP (versión con PHP 8.5 x64 en C:\xampp), copiar driver/php_oci8_19.dll dentro de C:\xampp\php\ext\

-Abrir C:\xampp\php\php.ini, agregar la línea extension=oci8_19 (debajo de extension=mysqli) y presionar Start en Apache




---------------PÁGINA-WEB---------------

-Copiar la carpeta esports_maule dentro de C:\xampp\htdocs\

-Entrar en el navegador a http://localhost/esports_maule/ e iniciar sesión con admin@esportsmaule.cl / admin123.




---------------DATO---------------

-De momento en la carpeta esport_maule(PÁGINA-WEB) tiene 3 carpetas "vacias": mantenedores, gestores y reportes.

-El .gitkeep es para que GitHub no las borre por ser carpetas vacias. Ahi se suponen que irian archivos PHP.
