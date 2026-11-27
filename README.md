---------------DATABASE---------------

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