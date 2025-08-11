const express = require('express');
const cors = require('cors');
require('dotenv').config(); // lee .env

const materiales = require('./routes/materiales.routes');
const reservas = require('./routes/reservas.routes');
const prestamos = require('./routes/prestamos.routes');
const devoluciones = require('./routes/devoluciones.routes');
const reportes = require('./routes/reportes.routes');
const usuarios = require('./routes/usuarios.routes');
const multas = require('./routes/multas.routes');





const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Healthcheck
app.get('/', (_req, res) => {
  res.json({ ok: true, api: 'Bibliotrack API', version: '1.0.0' });
});

// Rutas
app.use('/api/multas', multas);
app.use('/api/materiales', materiales);
app.use('/api/reservas', reservas);
app.use('/api/prestamos', prestamos);
app.use('/api/devoluciones', devoluciones);
app.use('/api/reportes', reportes);
app.use('/api/usuarios', usuarios);
// 404
app.use((_req, res) => {
  res.status(404).json({ ok: false, error: 'Ruta no encontrada' });
});

// Lanzar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API lista en http://localhost:${PORT}`);
});
