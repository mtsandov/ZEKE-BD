-- 04_triggers.sql
USE bibliotrack;
DELIMITER $$

-- No más de 3 reservas activas por usuario
CREATE TRIGGER trg_reserva_limit BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM reserva WHERE id_usuario=NEW.id_usuario AND estado_reserva='activa') >= 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Máximo de 3 reservas activas';
  END IF;
END$$

-- Marcar reserva vencida automáticamente si expira (cuando se actualiza cualquier registro)
CREATE TRIGGER trg_reserva_vencida BEFORE UPDATE ON reserva
FOR EACH ROW
BEGIN
  IF NEW.estado_reserva='activa' AND NEW.fecha_expiracion < NOW() THEN
    SET NEW.estado_reserva='vencida';
  END IF;
END$$

DELIMITER ;
