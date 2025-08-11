const router = require('express').Router();
const pool = require('../db/pool');

// Crear reserva (expira en 48h por defecto)
router.post('/', async (req, res) => {
  const { id_usuario, id_ejemplar } = req.body;
  if (!id_usuario || !id_ejemplar) {
    return res.status(400).json({ ok: false, error: 'id_usuario y id_ejemplar son obligatorios' });
  }
  try {
    const [r] = await pool.query(
      `INSERT INTO reserva (id_ejemplar, id_usuario, fecha_expiracion)
       VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 2 DAY))`,
      [id_ejemplar, id_usuario]
    );
    res.status(201).json({ ok: true, id_reserva: r.insertId });
  } catch (e) {
    res.status(400).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

// Cancelar reserva
router.patch('/:id/cancelar', async (req, res) => {
  try {
    const [r] = await pool.query(
      `UPDATE reserva SET estado_reserva='cancelada' WHERE id_reserva=?`,
      [req.params.id]
    );
    res.json({ ok: true, changedRows: r.affectedRows });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Listar reservas activas por usuario
router.get('/usuario/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM reserva
       WHERE id_usuario=? AND estado_reserva='activa'
       ORDER BY fecha_reserva DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

module.exports = router;
