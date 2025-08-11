const router = require('express').Router();
const pool = require('../db/pool');

// Crear préstamo usando SP (valida usuario, multas, reservas ajenas y estado del ejemplar)
router.post('/', async (req, res) => {
  const { id_usuario, id_ejemplar, fecha_esperada } = req.body;
  if (!id_usuario || !id_ejemplar || !fecha_esperada) {
    return res.status(400).json({ ok: false, error: 'id_usuario, id_ejemplar y fecha_esperada son obligatorios' });
  }
  try {
    await pool.query('CALL sp_registrar_prestamo(?,?,?)', [
      id_usuario,
      id_ejemplar,
      fecha_esperada // formato 'YYYY-MM-DD HH:MM:SS'
    ]);
    res.status(201).json({ ok: true, message: 'Préstamo creado' });
  } catch (e) {
    res.status(400).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

// Listar préstamos vigentes (no devueltos) por usuario
router.get('/usuario/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT * FROM prestamo
       WHERE id_usuario=? AND estado_dev=FALSE
       ORDER BY fecha_prest DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

module.exports = router;
