---------------DATABASE---------------


Encender servicios de Oracle XE en Windows
*(Solo si aparece el error `ORA-12541: No hay ningún listener`)*

1. Presionar Win + R, escribir services.msc
2. Buscar en la lista los siguientes dos servicios, hacer clic derecho sobre cada uno y presionar **Iniciar** (deben quedar en estado *En ejecución*):
   - OracleOraDB21Home1TNSListener
   - OracleServiceXE


Abrir SQL Developer y hacer clic en el botón verde `+` (Nueva conexión).
2. Configurar la conexión de administrador con estos datos exactos:
   - **Name:** `SYSTEM_XE`
   - **Usuario:** `SYSTEM`
   - **Contraseña:** *(la clave que definiste al instalar Oracle XE)*
   - **Nombre del Host:** `localhost`
   - **Puerto:** `1521`
   - **Nombre del Servicio:** *(marcar el círculo de Nombre del Servicio, NO SID)* -> **`XEPDB1`**
3. Presionar **Probar** (debe decir *Estado: Correcto*) y luego **Conectar**.
4. En la hoja de trabajo SQL que se abre, pegar y ejecutar (`F5`) estas dos líneas:
   ```sql
   CREATE USER ESPORTS_DB IDENTIFIED BY esports2026;
   GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO ESPORTS_DB;

-Abrir Oracle SQL Developer, conectarse como ESPORTS_DB (clave esports2026), abrir database/main.sql y ejecutar todo con F5.



---------------DRIVER---------------

-Instalar XAMPP (versión con PHP 8.5 x64 en C:\xampp), copiar driver/php_oci8_19.dll dentro de C:\xampp\php\ext\

-Abrir C:\xampp\php\php.ini, agregar la línea extension=oci8_19 (debajo de extension=mysqli) y presionar Start en Apache




---------------PÁGINA-WEB---------------

-Copiar la carpeta esports_maule dentro de C:\xampp\htdocs\

-Entrar en el navegador a http://localhost/esports_maule/ e iniciar sesión con admin@esportsmaule.cl / admin123.




---------------DATO---------------

-De momento en la carpeta esport_maule(PÁGINA-WEB) tiene 3 carpetas "vacias": mantenedores, gestores y reportes.

-El .gitkeep es para que GitHub no las borre por ser carpetas vacias. Ahi se suponen que irian archivos PHP.
