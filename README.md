
## PASO 1: Encender servicios de Oracle XE en Windows
*(Realizar solo si aparece el error `ORA-12541: No hay ningún listener en host localhost port 1521`)*

1. Presionar `Win + R`, escribir **`services.msc`** y presionar **Enter**.
2. Buscar en la lista los siguientes dos servicios, hacer clic derecho sobre cada uno y presionar **Iniciar** (ambos deben quedar en estado *En ejecución*):
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

## PASO 4: Instalar XAMPP y activar el driver de Oracle (`oci8`)

1. Instalar **XAMPP** (versión con **PHP 8.5 x64**) manteniendo la ruta por defecto **`C:\xampp`**.
2. Copiar el archivo **`driver/php_oci8_19.dll`** de este repositorio y pegarlo dentro de:
   ```text
   C:\xampp\php\ext\
   ```
3. Abrir el panel de control de **XAMPP**, hacer clic en **Config** (en la fila de **Apache**) y abrir **`PHP (php.ini)`**.
4. Buscar la línea `extension=mysqli` (`Ctrl + B`), presionar **Enter** debajo de ella y agregar exactamente:
   ```ini
   extension=oci8_19
   ```
5. Guardar el archivo (`Ctrl + S`).
6. En el panel de **XAMPP**, presionar **Start** en **Apache** (debe quedar resaltado en verde con los puertos `80, 443`).

---

## PASO 5: Montar y abrir la Página Web

1. Copiar la carpeta completa **`esports_maule`** de este repositorio y pegarla dentro de:
   ```text
   C:\xampp\htdocs\
   ```
   *(Debe quedar como `C:\xampp\htdocs\esports_maule\`)*
2. Abrir el navegador y entrar a:
   ```text
   http://localhost/esports_maule/
   ```
3. Iniciar sesión con las credenciales de demostración:
   - **Correo:** `admin@esportsmaule.cl`
   - **Contraseña:** `admin123`
