const router = require('express').Router();
const pool = require('../db/pool');

/** Pagar una multa por id (simple, sin SP) */
router.patch('/:id/pagar', async (req, res) => {
  try {
    const [r] = await pool.query(
      `UPDATE multa
       SET estado_multa='pagada', fecha_pago=NOW()
       WHERE id_multa=? AND estado_multa='pendiente'`,
      [req.params.id]
    );
    if (!r.affectedRows) {
      return res.status(400).json({ ok:false, error:'No existe o ya estaba pagada' });
    }
    res.json({ ok:true, id_multa: Number(req.params.id) });
  } catch (e) {
    res.status(500).json({ ok:false, error: e.message });
  }
});

/** Pagar TODAS las multas pendientes de un usuario (demo) */
router.patch('/usuario/:id/pagar-todo', async (req, res) => {
  try {
    const [r] = await pool.query(
      `UPDATE multa m
         JOIN prestamo p ON p.id_prestamo = m.id_prestamo
       SET m.estado_multa='pagada', m.fecha_pago=NOW()
       WHERE p.id_usuario=? AND m.estado_multa='pendiente'`,
      [req.params.id]
    );
    res.json({ ok:true, usuario: Number(req.params.id), pagadas: r.affectedRows });
  } catch (e) {
    res.status(500).json({ ok:false, error: e.message });
  }
});

module.exports = router;
