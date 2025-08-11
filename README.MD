📚 Bibliotrack API
Un sistema de gestión de biblioteca robusto y completo construido con Node.js + Express y respaldado por una base de datos MySQL. El sistema está diseñado para manejar todas las operaciones críticas de una biblioteca, desde la catalogación de materiales hasta la gestión de multas.

✨ Características Principales
📦 Gestión de Catálogo Extensa: Soporta múltiples tipos de materiales, incluyendo libros, revistas, tesis, CD/DVD, dispositivos tecnológicos y juegos educativos.

✍️ Múltiples Autores: Maneja correctamente la relación N:M entre materiales y autores.

📋 Control de Inventario: Realiza un seguimiento de cada ejemplar físico, su ubicación, y estado (disponible, prestado, en reparación, etc.).

👥 Administración de Usuarios: Sistema de roles (admin, estudiante, docente) con permisos definidos.

⚙️ Lógica de Negocio Transaccional: Incluye un flujo completo para reservas, préstamos, devoluciones y cálculo automático de multas por retraso.

🛡️ Auditoría y Seguridad: Registra todas las acciones importantes en un historial para seguimiento y control.

🚀 Lógica de Base de Datos Optimizada: Utiliza Stored Procedures, Triggers y Vistas para encapsular la lógica de negocio, mejorar el rendimiento y garantizar la integridad de los datos.

🛠️ Stack Tecnológico
Backend: Node.js, Express.js

Base de Datos: MySQL

Frontend (potencial): Preparado para ser consumido por cualquier framework como Angular, React o Vue.

🚀 Cómo Empezar
Sigue estos pasos para configurar y ejecutar el proyecto en tu entorno local.

Prerrequisitos
Node.js (v18 o superior)

NPM

Una instancia de MySQL Server en ejecución.

Instalación y Ejecución
Clona el repositorio:

Bash

git clone https://github.com/tu-usuario/bibliotrack-api.git
cd bibliotrack-api
Instala las dependencias:

Bash

npm install
Configura las variables de entorno:
Crea un archivo .env en la raíz del proyecto y añade la configuración de tu base de datos.

Ini, TOML

# Puerto de la aplicación
PORT=3000

# Configuración de la Base de Datos MySQL
DB_HOST=localhost
DB_USER=root
DB_PASS=TU_PASSWORD_SECRETO
DB_NAME=bibliotrack
DB_PORT=3306
Ejecuta el servidor en modo de desarrollo:
El servidor se reiniciará automáticamente con cada cambio.

Bash

npm run dev
El API estará disponible en http://localhost:3000.

🗄️ Diseño de la Base de Datos (bibliotrack)
La base de datos está normalizada y estructurada para ser eficiente y escalable.

Tablas Principales
Tabla	Descripción
categoria	Catálogo de categorías de materiales (ej. "Ciencia Ficción", "Investigación").
tipo_usuario	Roles y permisos de los usuarios en formato JSON.
material_bibliografico	Registro base que contiene la información común de todos los materiales.
Subtablas de material	libro, revista, tesis, cd, dvd, dispositivo_tecnologico, juego_educativo. Heredan de material_bibliografico.
autor	Catálogo de autores registrados en el sistema.
material_autor	Tabla pivote para la relación N:M entre material_bibliografico y autor.
ejemplar_fisico	Cada copia física de un material, con su ubicación, código de inventario y estado.
usuario	Datos de los usuarios registrados, su rol y el estado de su cuenta (activo, bloqueado).
reserva	Reservas de ejemplares con fecha de expiración y estado (activa, vencida, cancelada, atendida).
prestamo	Registro de préstamos de ejemplares, con fechas de préstamo, devolución esperada y estado.
multa	Multas generadas automáticamente y asociadas a préstamos devueltos con retraso.
historial_accion	Tabla de auditoría que registra las acciones relevantes realizadas por los usuarios.

Exportar a Hojas de cálculo
⚙️ Stored Procedures (Lógica de Negocio)
sp_registrar_prestamo(p_id_usuario, p_id_ejemplar, p_fecha_esperada)
Encapsula la lógica para registrar un nuevo préstamo.

Validaciones:

Verifica que el usuario esté activo.

Comprueba que el usuario no tenga multas pendientes de pago.

Confirma que el ejemplar esté disponible.

Impide el préstamo si el ejemplar está reservado por otro usuario.

Acciones:

Inserta el nuevo registro en la tabla prestamo.

Actualiza el estado del ejemplar_fisico a prestado.

Si el mismo usuario tenía el ejemplar reservado, actualiza el estado de la reserva a atendida.

Registra la transacción en historial_accion.

SQL

CALL sp_registrar_prestamo(2, 5, DATE_ADD(NOW(), INTERVAL 3 DAY));
sp_registrar_devolucion(p_id_prestamo, p_fecha_dev)
Gestiona la devolución de un ejemplar.

Acciones:

Actualiza la fecha_dev y el estado_dev del préstamo.

Cambia el estado del ejemplar_fisico de vuelta a disponible.

Genera una multa si p_fecha_dev es posterior a la fecha_esperada (tasa de 0.50 por día de atraso).

Registra la devolución en historial_accion.

SQL

CALL sp_registrar_devolucion(3, NOW());
⛔ Triggers (Reglas Automáticas)
trg_reserva_limit
Se ejecuta BEFORE INSERT en la tabla reserva.

Restricción: Impide que un usuario tenga más de 3 reservas activas simultáneamente.

SQL

-- Lógica del Trigger
IF (SELECT COUNT(*) FROM reserva WHERE id_usuario=NEW.id_usuario AND estado_reserva='activa') >= 3 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Límite de 3 reservas activas alcanzado.';
END IF;
trg_reserva_vencida
Se ejecuta BEFORE UPDATE en la tabla reserva.

Lógica: Si la fecha actual ha superado la fecha_expiracion y la reserva sigue activa, la cambia automáticamente a vencida.

👓 Vistas (Reportes Rápidos)
vw_disponibilidad: Un listado completo de todos los materiales y sus ejemplares, mostrando su estado actual (disponible, prestado, reservado, etc.).

vw_multas_usuario: Un resumen de todas las multas (pendientes y pagadas) agrupadas por usuario.

🌐 API Endpoints
A continuación se detallan los endpoints principales del API.

Healthcheck
GET / - Verifica que el API esté funcionando correctamente.

JSON

{
  "ok": true,
  "api": "Bibliotrack API",
  "version": "1.0.0"
}
Materiales
GET /api/materiales - Lista todos los materiales.

GET /api/materiales?q=texto - Busca materiales por título o autor.

GET /api/materiales/:id - Obtiene los detalles de un material específico.

GET /api/materiales/:id/ejemplares - Lista todos los ejemplares físicos de un material.

Reservas
POST /api/reservas - Crea una nueva reserva para un usuario y un ejemplar.

JSON

{
  "id_usuario": 1,
  "id_ejemplar": 1
}
PATCH /api/reservas/:id/cancelar - Cancela una reserva activa.

GET /api/reservas/usuario/:id - Lista todas las reservas de un usuario.

Préstamos y Devoluciones
POST /api/prestamos - Registra un nuevo préstamo (ejecuta sp_registrar_prestamo).

JSON

{
  "id_usuario": 2,
  "id_ejemplar": 5,
  "fecha_esperada": "2025-08-15 12:00:00"
}
POST /api/devoluciones - Registra una devolución (ejecuta sp_registrar_devolucion).

JSON

{
  "id_prestamo": 3,
  "fecha_dev": "2025-08-16 10:00:00"
}
GET /api/prestamos/usuario/:id - Obtiene el historial de préstamos de un usuario.

Reportes
GET /api/reportes/disponibilidad - Devuelve los datos de la vista vw_disponibilidad.

GET /api/reportes/multas - Devuelve los datos de la vista vw_multas_usuario.

📌 Ejemplo de Flujo de Prueba
Listar todos los materiales para ver qué hay disponible:
GET /api/materiales

Ver los ejemplares de un material de interés (ej: con ID 1):
GET /api/materiales/1/ejemplares

Crear una reserva para el usuario 1 sobre el ejemplar 1:
POST /api/reservas con {"id_usuario": 1, "id_ejemplar": 1}

Realizar un préstamo directo para el usuario 2 con el ejemplar 5, con 3 días de plazo:
POST /api/prestamos con {"id_usuario": 2, "id_ejemplar": 5, "fecha_esperada": "2025-08-18 10:00:00"}

Consultar los préstamos activos del usuario 2:
GET /api/prestamos/usuario/2

Registrar la devolución del préstamo anterior:
POST /api/devoluciones con el id_prestamo obtenido en el paso 5.

Consultar los reportes para ver el estado general:
GET /api/reportes/disponibilidad
GET /api/reportes/multas