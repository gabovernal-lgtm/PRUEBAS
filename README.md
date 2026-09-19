OPERACIONES DDH — PRUEBAS: HISTORIAL MEJORADO + ACCESO DE USUARIOS

Esta versión mantiene los módulos, PDF, compartir PDF de prueba y aprobación de usuarios de la versión anterior. No incorpora seguimiento de estados de solicitudes.

HISTORIAL NUEVO: filtros por tipo, texto y fecha de creación; exportación CSV de los registros filtrados (se abre en Excel); carga por páginas de hasta 20.000 registros. Para reporte de traslados, seleccionar TRASLADO; para tricono, SRM. Los registros ya guardados se muestran si la base conectada los contiene y el usuario tiene permiso.

BASE DE DATOS: La tabla historial_operaciones del setup_pruebas.sql YA TIENE LOS CAMPOS NECESARIOS. NO hay que borrarla ni reemplazarla para esta mejora. Si ya configuraste el proyecto Supabase de pruebas y funciona el historial, NO vuelvas a ejecutar el SQL: solo reemplaza los archivos web. Si NO has configurado un proyecto de pruebas, sigue los pasos de abajo.

1. Abre https://supabase.com/dashboard, selecciona o crea un PROYECTO DE PRUEBAS distinto del oficial.
2. En SQL Editor > New query, ejecuta setup_pruebas.sql SOLO en el proyecto nuevo. NO ejecutes ese archivo en el proyecto oficial: incluye reglas de autenticación y permisos que podrían interrumpir la app oficial.
3. En Project Settings > API (o Connect > API keys, según la interfaz) copia Project URL y la clave publicable/anon a config.js. NUNCA pongas service_role ni secret keys en GitHub.
4. En Authentication > Providers > Email habilita correo y confirmación. En Authentication > URL Configuration configura la URL exacta del repositorio de pruebas en Site URL y Redirect URLs. Para envío real de correos puede requerirse SMTP corporativo.
5. Sube al repositorio de pruebas index.html, config.js, sw.js, manifest.webmanifest e icon.svg. Haz Commit changes. No subas setup_pruebas.sql a un repositorio público.
6. Registra gvernal@geotec.cl con contraseña nueva, confirma el correo y, desde SQL Editor del proyecto de pruebas, ejecuta: select public.ddh_bootstrap_admin('gvernal@geotec.cl');
7. Inicia sesión y prueba: crear solicitud de traslado, crear SRM, abrir Historial, filtrar por tipo y exportar CSV. Comprueba en Supabase > Table Editor > historial_operaciones que aparecen los registros.

NOTAS: La base de pruebas comienza vacía. La base oficial y sus datos NO se cambian ni se migran. El CSV incluye únicamente los campos que el historial actual almacena; no incluye PDF adjuntos ni campos individuales que no se guardan. El límite de 20.000 registros es una salvaguarda del navegador. Las funciones de registro de usuario y recuperación de contraseña necesitan Supabase configurado y no se han probado aquí con correos reales.
