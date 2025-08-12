-- 02_views.sql
USE bibliotrack;

CREATE OR REPLACE VIEW vw_disponibilidad AS
SELECT m.id_material, m.titulo, e.id_ejemplar, e.estado
FROM material_bibliografico m
JOIN ejemplar_fisico e ON e.id_material = m.id_material;

CREATE OR REPLACE VIEW vw_multas_usuario AS
SELECT u.id_usuario, u.nombre,
       COALESCE(SUM(CASE WHEN mu.estado_multa='pendiente' THEN mu.monto ELSE 0 END),0) AS deuda_pendiente,
       COALESCE(SUM(CASE WHEN mu.estado_multa='pagada' THEN mu.monto ELSE 0 END),0) AS pagado
FROM usuario u
LEFT JOIN prestamo p ON p.id_usuario=u.id_usuario
LEFT JOIN multa mu ON mu.id_prestamo=p.id_prestamo
GROUP BY u.id_usuario, u.nombre;

DROP VIEW IF EXISTS vw_reservas_activas;
CREATE VIEW vw_reservas_activas AS
SELECT
  r.id_reserva,
  r.id_ejemplar,
  e.id_material,
  m.titulo,
  r.id_usuario,
  u.nombre       AS usuario,
  r.fecha_reserva,
  r.fecha_expiracion,
  CASE
    WHEN r.estado_reserva = 'activa' AND NOW() > r.fecha_expiracion THEN 'vencida'
    ELSE r.estado_reserva
  END AS estado_reserva_calc
FROM reserva r
JOIN ejemplar_fisico       e ON e.id_ejemplar = r.id_ejemplar
JOIN material_bibliografico m ON m.id_material = e.id_material
JOIN usuario               u ON u.id_usuario = r.id_usuario
WHERE r.estado_reserva IN ('activa','vencida');

DROP VIEW IF EXISTS vw_ejemplares_reservados;
CREATE VIEW vw_ejemplares_reservados AS
SELECT
  e.id_ejemplar,
  e.id_material,
  m.titulo,
  e.estado               AS estado_ejemplar,
  EXISTS(
    SELECT 1
    FROM reserva r
    WHERE r.id_ejemplar = e.id_ejemplar
      AND r.estado_reserva = 'activa'
      AND r.fecha_expiracion >= NOW()
  ) AS tiene_reserva_activa
FROM ejemplar_fisico e
JOIN material_bibliografico m ON m.id_material = e.id_material;
