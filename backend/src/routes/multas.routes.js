const router = require('express').Router();
const pool = require('../db/pool');

/**
 * GET /api/multas/usuario/:id
 * Lista las multas (pendientes y pagadas) de un usuario.
 * Requiere SP: sp_listar_multas_usuario(IN p_id_usuario INT)
 */
router.get('/usuario/:id', async (req, res) => {
  const userId = Number(req.params.id);
  if (!Number.isInteger(userId)) {
    return res.status(400).json({ ok: false, error: 'id_usuario inválido' });
  }

  try {
    const [rows] = await pool.query('CALL sp_listar_multas_usuario(?)', [userId]);
    // mysql2 con CALL retorna [[resultset], meta...]
    const data = Array.isArray(rows) ? rows[0] : [];
    res.json(data);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

/**
 * PATCH /api/multas/:id/pagar
 * Paga UNA multa por id (estado_multa -> 'pagada', fecha_pago -> NOW()).
 * Requiere SP: sp_pagar_multa(IN p_id_multa INT)
 * Respuesta: { ok:true, id_multa, estado:'pagada' }
 */
router.patch('/:id/pagar', async (req, res) => {
  const multaId = Number(req.params.id);
  if (!Number.isInteger(multaId)) {
    return res.status(400).json({ ok: false, error: 'id_multa inválido' });
  }

  try {
    const [rows] = await pool.query('CALL sp_pagar_multa(?)', [multaId]);
    const out = rows?.[0]?.[0] || { id_multa: multaId, estado: 'pagada' };
    res.json({ ok: true, ...out });
  } catch (e) {
    // Mensajes generados con SIGNAL en el SP llegan con sqlState 45000
    res.status(400).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

/**
 * PATCH /api/multas/usuario/:id/pagar-todo
 * Paga TODAS las multas pendientes de un usuario.
 * Requiere SP: sp_pagar_multas_usuario(IN p_id_usuario INT)
 * Respuesta: { ok:true, id_usuario, pagadas }
 */
router.patch('/usuario/:id/pagar-todo', async (req, res) => {
  const userId = Number(req.params.id);
  if (!Number.isInteger(userId)) {
    return res.status(400).json({ ok: false, error: 'id_usuario inválido' });
  }

  try {
    const [rows] = await pool.query('CALL sp_pagar_multas_usuario(?)', [userId]);
    const out = rows?.[0]?.[0] || { id_usuario: userId, pagadas: 0 };
    res.json({ ok: true, ...out });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

module.exports = router;
