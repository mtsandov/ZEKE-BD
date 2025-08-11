const router = require('express').Router();
const pool = require('../db/pool');

// Lista usuarios con su tipo/rol
router.get('/', async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT u.id_usuario, u.nombre, u.correo, u.id_tipo_usuario,
             t.rol AS tipo, t.permisos
      FROM usuario u
      JOIN tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario
      ORDER BY u.id_usuario
    `);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
