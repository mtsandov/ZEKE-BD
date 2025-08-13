-- 03_procedures.sql
USE bibliotrack;
DELIMITER $$

-- Registrar préstamo con validaciones
CREATE PROCEDURE sp_registrar_prestamo(
  IN p_id_usuario INT,
  IN p_id_ejemplar INT,
  IN p_fecha_esperada DATETIME
)
BEGIN
  DECLARE v_estado_user VARCHAR(20);
  DECLARE v_estado_ej VARCHAR(20);
  DECLARE v_multas INT DEFAULT 0;
  DECLARE v_reserva_ajena INT DEFAULT 0;

  SELECT estado_cuenta INTO v_estado_user FROM usuario WHERE id_usuario = p_id_usuario;
  IF v_estado_user <> 'activo' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Usuario no activo';
  END IF;

  SELECT COUNT(*) INTO v_multas
  FROM multa m
  JOIN prestamo p ON p.id_prestamo = m.id_prestamo
  WHERE p.id_usuario = p_id_usuario AND m.estado_multa='pendiente';
  IF v_multas > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Usuario con multas pendientes';
  END IF;

  SELECT estado INTO v_estado_ej FROM ejemplar_fisico WHERE id_ejemplar = p_id_ejemplar FOR UPDATE;
  IF v_estado_ej <> 'disponible' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ejemplar no disponible';
  END IF;

  SELECT COUNT(*) INTO v_reserva_ajena
  FROM reserva
  WHERE id_ejemplar = p_id_ejemplar AND estado_reserva='activa' AND id_usuario <> p_id_usuario;
  IF v_reserva_ajena > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ejemplar reservado por otro usuario';
  END IF;

  INSERT INTO prestamo(id_ejemplar,id_usuario,fecha_esperada)
  VALUES(p_id_ejemplar,p_id_usuario,p_fecha_esperada);

  UPDATE ejemplar_fisico SET estado='prestado' WHERE id_ejemplar=p_id_ejemplar;

  UPDATE reserva SET estado_reserva='atendida'
   WHERE id_ejemplar=p_id_ejemplar AND id_usuario=p_id_usuario AND estado_reserva='activa';

  INSERT INTO historial_accion(id_usuario,tipo_accion,descripcion)
  VALUES(p_id_usuario,'prestamo','Préstamo registrado con ejemplar ' );
END$$

-- Registrar devolución y calcular multa por atraso (0.50 por día)
CREATE PROCEDURE sp_registrar_devolucion(
  IN p_id_prestamo INT,
  IN p_fecha_dev DATETIME
)
BEGIN
  DECLARE v_id_user INT; 
  DECLARE v_id_ej INT; 
  DECLARE v_fecha_esp DATETIME;

  SELECT id_usuario,id_ejemplar,fecha_esperada
  INTO v_id_user,v_id_ej,v_fecha_esp
  FROM prestamo WHERE id_prestamo=p_id_prestamo FOR UPDATE;

  UPDATE prestamo SET fecha_dev=p_fecha_dev, estado_dev=TRUE WHERE id_prestamo=p_id_prestamo;
  UPDATE ejemplar_fisico SET estado='disponible' WHERE id_ejemplar=v_id_ej;

  IF p_fecha_dev > v_fecha_esp THEN
    INSERT INTO multa(id_prestamo,monto)
    VALUES(p_id_prestamo, 0.50 * DATEDIFF(p_fecha_dev, v_fecha_esp));
  END IF;

  INSERT INTO historial_accion(id_usuario,tipo_accion,descripcion)
  VALUES(v_id_user,'devolucion','Devolución del préstamo ' );
END$$

DELIMITER ;


-- ============================================
-- SP: pagar UNA multa por id
-- ============================================
DROP PROCEDURE IF EXISTS sp_pagar_multa;
DELIMITER $$
CREATE PROCEDURE sp_pagar_multa(IN p_id_multa INT)
BEGIN
  DECLARE v_estado VARCHAR(20);

  -- leer y bloquear la fila
  SELECT estado_multa INTO v_estado
  FROM multa
  WHERE id_multa = p_id_multa
  FOR UPDATE;

  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La multa no existe';
  ELSEIF v_estado = 'pagada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La multa ya está pagada';
  END IF;

  UPDATE multa
  SET estado_multa='pagada', fecha_pago=NOW()
  WHERE id_multa = p_id_multa;

  -- respuesta simple para el cliente
  SELECT p_id_multa AS id_multa, 'pagada' AS estado;
END$$
DELIMITER ;

-- ============================================
-- SP: pagar TODAS las multas pendientes de un usuario
-- Devuelve una fila con {id_usuario, pagadas}
-- ============================================
DROP PROCEDURE IF EXISTS sp_pagar_multas_usuario;
DELIMITER $$
CREATE PROCEDURE sp_pagar_multas_usuario(IN p_id_usuario INT)
BEGIN
  DECLARE v_pagadas INT DEFAULT 0;

  START TRANSACTION;

    UPDATE multa m
    JOIN prestamo p ON p.id_prestamo = m.id_prestamo
    SET m.estado_multa='pagada', m.fecha_pago=NOW()
    WHERE p.id_usuario = p_id_usuario
      AND m.estado_multa='pendiente';

    SET v_pagadas = ROW_COUNT();

  COMMIT;

  SELECT p_id_usuario AS id_usuario, v_pagadas AS pagadas;
END$$
DELIMITER ;

-- (opcional) SP: listar multas de un usuario (para UI)
DROP PROCEDURE IF EXISTS sp_listar_multas_usuario;
DELIMITER $$
CREATE PROCEDURE sp_listar_multas_usuario(IN p_id_usuario INT)
BEGIN
  SELECT m.id_multa, m.id_prestamo, m.monto, m.estado_multa, m.fecha_emision, m.fecha_pago
  FROM multa m
  JOIN prestamo p ON p.id_prestamo = m.id_prestamo
  WHERE p.id_usuario = p_id_usuario
  ORDER BY m.id_multa DESC;
END$$
DELIMITER ;