const router = require('express').Router();
const pool = require('../db/pool');

// Registrar devolución (SP calcula multa si hay atraso)
router.post('/', async (req, res) => {
  const { id_prestamo, fecha_dev } = req.body;
  if (!id_prestamo || !fecha_dev) {
    return res.status(400).json({ ok: false, error: 'id_prestamo y fecha_dev son obligatorios' });
  }
  try {
    await pool.query('CALL sp_registrar_devolucion(?,?)', [id_prestamo, fecha_dev]);
    res.json({ ok: true, message: 'Devolución registrada' });
  } catch (e) {
    res.status(400).json({ ok: false, error: e.sqlMessage || e.message });
  }
});

module.exports = router;
