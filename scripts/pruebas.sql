USE bibliotrack;

-- =========================================================
-- 0) Helper: ver estado rápido
-- =========================================================
-- Ver ejemplares
SELECT id_ejemplar, id_material, estado, ubicacion_fisica, cod_inv FROM ejemplar_fisico ORDER BY id_ejemplar;
-- Ver reservas
SELECT * FROM reserva ORDER BY id_reserva DESC;
-- Ver préstamos
SELECT * FROM prestamo ORDER BY id_prestamo DESC;
-- Ver multas
SELECT * FROM multa ORDER BY id_multa DESC;
-- Ver reportes
SELECT * FROM vw_disponibilidad ORDER BY id_ejemplar;
SELECT * FROM vw_multas_usuario ORDER BY id_usuario;

-- =========================================================
-- 1) Trigger trg_reserva_limit  (Máx 3 reservas activas por usuario)
-- =========================================================
-- Limpieza mínima de reservas del usuario 1 (opcional para partida limpia)
DELETE FROM reserva WHERE id_usuario=1;

-- Crear 3 reservas activas para usuario 1 (Ana) en ejemplares distintos
-- OJO: usa ejemplares que estén 'disponible'
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_expiracion) VALUES (2,1, DATE_ADD(NOW(), INTERVAL 2 DAY));
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_expiracion) VALUES (3,1, DATE_ADD(NOW(), INTERVAL 2 DAY));
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_expiracion) VALUES (4,1, DATE_ADD(NOW(), INTERVAL 2 DAY));

-- Intento de 4ta reserva (DEBE FALLAR con el mensaje del trigger)
-- Espera error: "Máximo de 3 reservas activas"
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_expiracion) VALUES (5,1, DATE_ADD(NOW(), INTERVAL 2 DAY));

-- Verifica:
SELECT id_usuario, estado_reserva, COUNT(*) AS reservas_activas
FROM reserva WHERE id_usuario=1 AND estado_reserva='activa';

-- =========================================================
-- 2) Procedure sp_registrar_prestamo  (flujo OK)
-- =========================================================
-- Asegúrate de tener un ejemplar 'disponible' (ej. 5 o el que veas disponible)
SELECT id_ejemplar, estado FROM ejemplar_fisico;

-- Préstamo para Luis (id_usuario=2) con devolución esperada en 3 días
CALL sp_registrar_prestamo(2, 2, DATE_ADD(NOW(), INTERVAL 3 DAY));

-- Debe existir un préstamo nuevo y el ejemplar cambiar a 'prestado'
SELECT * FROM prestamo WHERE id_usuario=2 ORDER BY id_prestamo DESC LIMIT 3;
SELECT id_ejemplar, estado FROM ejemplar_fisico WHERE id_ejemplar=2;

-- =========================================================
-- 3) Procedure sp_registrar_prestamo  (bloqueo por reserva ajena)
-- =========================================================
-- Prepara: usuario 1 reserva el ejemplar 1
DELETE FROM reserva WHERE id_ejemplar=1; -- limpieza por si existía
UPDATE ejemplar_fisico SET estado='disponible' WHERE id_ejemplar=1;
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_expiracion,estado_reserva)
VALUES (1,2, DATE_ADD(NOW(), INTERVAL 1 DAY), 'activa');

-- Ahora intenta prestar ese mismo ejemplar al usuario 2 (DEBE FALLAR)
-- Espera error: "Ejemplar reservado por otro usuario"
CALL sp_registrar_prestamo(3, 1, DATE_ADD(NOW(), INTERVAL 5 DAY));

-- =========================================================
-- 4) Procedure sp_registrar_devolucion  (con multa por atraso)
-- =========================================================
-- Prepara un préstamo atrasado: crea uno con fecha_esperada en el pasado
-- Paso A: dejar libre un ejemplar (ej. 4)
UPDATE ejemplar_fisico SET estado='disponible' WHERE id_ejemplar=3;
-- Paso B: prestar a Luis con fecha esperada HACE 2 días
CALL sp_registrar_prestamo(3, 3, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- Identifica el id_prestamo creado (toma el más reciente de Luis sin devolver)
SELECT id_prestamo, id_ejemplar, fecha_esperada, estado_dev
FROM prestamo
WHERE id_usuario=2 AND estado_dev=FALSE
ORDER BY id_prestamo DESC
LIMIT 1;

-- Suponiendo que el último ID es X, devuelve con fecha HOY (2 días tarde)
-- Reemplaza X por el id real que te arrojó el SELECT anterior
SET @ID := (SELECT id_prestamo FROM prestamo WHERE id_usuario=2 AND estado_dev=FALSE ORDER BY id_prestamo DESC LIMIT 1);
CALL sp_registrar_devolucion(@ID, NOW());

-- Verifica: debe existir multa por 0.50 * días de atraso (≈ 1.00)
SELECT * FROM multa WHERE id_prestamo=3;
-- El ejemplar debe volver a 'disponible'
SELECT id_ejemplar, estado FROM ejemplar_fisico WHERE id_ejemplar=4;

-- =========================================================
-- 5) Procedure sp_registrar_devolucion  (a tiempo, sin multa)
-- =========================================================
-- Prepara otro préstamo con fecha_esperada futura
UPDATE ejemplar_fisico SET estado='disponible' WHERE id_ejemplar=3;
CALL sp_registrar_prestamo(2, 3, DATE_ADD(NOW(), INTERVAL 1 DAY));

-- Toma id del préstamo recién creado
SET @ID2 := (SELECT id_prestamo FROM prestamo WHERE id_usuario=2 AND estado_dev=FALSE ORDER BY id_prestamo DESC LIMIT 1);
-- Devuelve HOY (antes de la fecha_esperada)
CALL sp_registrar_devolucion(@ID2, NOW());

-- Verifica: NO debe crearse multa
SELECT * FROM multa WHERE id_prestamo=@ID2;

-- =========================================================
-- 6) Trigger trg_reserva_vencida  (marcar 'vencida' si expira)
-- =========================================================
-- Crea una reserva activa que expira "en el pasado"
INSERT INTO reserva(id_ejemplar,id_usuario,fecha_reserva,fecha_expiracion,estado_reserva)
VALUES (2,1, NOW(), DATE_SUB(NOW(), INTERVAL 1 DAY), 'activa');

-- El trigger es BEFORE UPDATE, así que forzamos una actualización "tonta"
-- que mantenga estado_reserva='activa' pero dispare el trigger.
SET @RID := (SELECT id_reserva FROM reserva WHERE id_usuario=1 ORDER BY id_reserva DESC LIMIT 1);
UPDATE reserva
SET estado_reserva='activa'   -- intento mantener activa
WHERE id_reserva=@RID;        -- el trigger debe cambiarla a 'vencida'

-- Verifica: ahora debe figurar 'vencida'
SELECT id_reserva, estado_reserva, fecha_expiracion FROM reserva WHERE id_reserva=@RID;

-- =========================================================
-- 7) Limpieza opcional de datos de prueba recientes (descomenta si quieres)
-- =========================================================
 DELETE FROM multa WHERE id_prestamo IN (SELECT id_prestamo FROM prestamo WHERE id_usuario=2);
DELETE FROM prestamo WHERE id_usuario=2;
 DELETE FROM reserva WHERE id_usuario IN (1,2);
 UPDATE ejemplar_fisico SET estado='disponible';
 
 
 
 -- Reserva/estado del ejemplar deben permitir prestar
-- Este ejemplo: usuario 3, ejemplar @idEjemplar, con devolución esperada hace 1 día
SET @idEjemplar := 3;  -- cambia por uno disponible
CALL sp_registrar_prestamo(2, @idEjemplar, DATE_SUB(NOW(), INTERVAL 1 DAY));

SELECT * FROM vw_multas_usuario;
