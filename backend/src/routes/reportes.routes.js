const router = require('express').Router();
const pool = require('../db/pool');

// Reporte: disponibilidad por ejemplar/material
router.get('/disponibilidad', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_disponibilidad');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// GET /api/reportes/reservas  -> lista reservas (activa/vencida) con detalle
router.get('/reservas', async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT *
      FROM vw_reservas_activas
      ORDER BY estado_reserva_calc='activa' DESC, fecha_expiracion ASC
    `);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok:false, error: e.message });
  }
});


// Reporte: multas por usuario
router.get('/multas', async (_req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_multas_usuario');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

module.exports = router;
