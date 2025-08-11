const router = require('express').Router();
const pool = require('../db/pool');

// Listar materiales (opcional: filtro ?q=)
router.get('/', async (req, res) => {
  try {
    const { q } = req.query;
    let sql = `
      SELECT m.*, c.nombre AS categoria
      FROM material_bibliografico m
      JOIN categoria c ON c.id_categoria = m.id_categoria
    `;
    const params = [];
    if (q) {
      sql += ' WHERE m.titulo LIKE ?';
      params.push(`%${q}%`);
    }
    sql += ' ORDER BY m.titulo';
    const [rows] = await pool.query(sql, params);
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Obtener material por id
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM material_bibliografico WHERE id_material=?',
      [req.params.id]
    );
    res.json(rows[0] || null);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Listar ejemplares físicos de un material
router.get('/:id/ejemplares', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM ejemplar_fisico WHERE id_material=? ORDER BY id_ejemplar',
      [req.params.id]
    );
    res.json(rows);
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

module.exports = router;
