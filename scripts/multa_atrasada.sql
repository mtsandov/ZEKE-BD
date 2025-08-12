-- ==========================
-- DEMO: Generar una MULTA por entrega atrasada
-- ==========================
USE bibliotrack;

-- 1) Tomar un usuario activo (o usar/crear uno de demo)
SET @uid := (SELECT id_usuario FROM usuario WHERE estado_cuenta='activo' LIMIT 1);
-- Si no hay ninguno, intenta usar 1 o 2 como fallback
SET @uid := COALESCE(@uid, (SELECT id_usuario FROM usuario WHERE id_usuario IN (1,2) LIMIT 1));

-- (Opcional) crear un usuario demo si aún no hay
INSERT INTO usuario (nombre, correo, estado_cuenta, id_tipo_usuario)
SELECT 'Demo Mora', 'demo@demo.com', 'activo',
       COALESCE((SELECT id_tipo_usuario FROM tipo_usuario LIMIT 1), 1)
WHERE @uid IS NULL;
SET @uid := COALESCE(@uid, LAST_INSERT_ID());

-- 2) Conseguir un ejemplar DISPONIBLE (si no hay, crear uno rápido)
SET @eid := (SELECT e.id_ejemplar
             FROM ejemplar_fisico e
             WHERE e.estado='disponible'
             LIMIT 1);

-- Si no hay ejemplares disponibles, creamos material + ejemplar de demo
-- Para id_categoria, usamos uno ya existente de cualquier material (evita FK)
SET @catMat := (SELECT id_categoria FROM material_bibliografico LIMIT 1);

INSERT INTO material_bibliografico (titulo, editorial, id_categoria, descripcion, anio_publicacion)
SELECT 'DEMO Atraso', 'Demo', COALESCE(@catMat, 1), 'Para probar mora', YEAR(CURDATE())
WHERE @eid IS NULL;

SET @idMat := LAST_INSERT_ID();

-- Generar un código de inventario nuevo (por si hay unique)
SET @newCodInv := (SELECT COALESCE(MAX(cod_inv), 990000) + 1 FROM ejemplar_fisico);

INSERT INTO ejemplar_fisico (id_material, estado, ubicacion_fisica, cod_inv)
SELECT @idMat, 'disponible', 'Estante DEMO', @newCodInv
WHERE @eid IS NULL;

SET @eid := COALESCE(@eid, LAST_INSERT_ID());

-- 3) Registrar PRÉSTAMO ya vencido (fecha_esperada hace 2 días)
CALL sp_registrar_prestamo(@uid, 5, DATE_SUB(NOW(), INTERVAL 2 DAY));

-- 4) Registrar DEVOLUCIÓN hoy (tarde) -> genera MULTA pendiente
-- Tomamos el último préstamo creado (si prefieres, guarda el id en una variable)
SET @idPrestamo := (SELECT id_prestamo FROM prestamo ORDER BY id_prestamo DESC LIMIT 1);
CALL sp_registrar_devolucion(@idPrestamo, NOW());

-- 5) Verificar la multa PENDIENTE del usuario
SELECT m.id_multa, m.id_prestamo, m.monto, m.estado_multa, m.fecha_emision
FROM multa m
JOIN prestamo p ON p.id_prestamo = m.id_prestamo
WHERE p.id_usuario = @uid
ORDER BY m.id_multa DESC;

-- 6) (Opcional) Probar que el préstamo queda BLOQUEADO por multa:
-- Debería dar error "Usuario con multas pendientes"
-- CALL sp_registrar_prestamo(@uid, @eid, DATE_ADD(NOW(), INTERVAL 3 DAY));
