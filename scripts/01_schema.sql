-- 01_schema.sql
DROP DATABASE IF EXISTS bibliotrack;
CREATE DATABASE bibliotrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bibliotrack;

-- Catálogos
CREATE TABLE categoria (
  id_categoria INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255)
);

CREATE TABLE tipo_usuario (
  id_tipo_usuario INT PRIMARY KEY AUTO_INCREMENT,
  rol VARCHAR(50) NOT NULL,
  permisos JSON NULL
);

-- Núcleo
CREATE TABLE material_bibliografico (
  id_material INT PRIMARY KEY AUTO_INCREMENT,
  titulo VARCHAR(200) NOT NULL,
  editorial VARCHAR(120),
  id_categoria INT NOT NULL,
  descripcion VARCHAR(500),
  anio_publicacion YEAR,
  CONSTRAINT fk_mat_cat FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

-- Subtipos (Table-per-Subtype)
CREATE TABLE libro (
  id_material INT PRIMARY KEY,
  isbn VARCHAR(20) UNIQUE,
  edicion VARCHAR(50),
  CONSTRAINT fk_lib_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE revista (
  id_material INT PRIMARY KEY,
  issn VARCHAR(20),
  volumen VARCHAR(20),
  numero VARCHAR(20),
  CONSTRAINT fk_rev_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE tesis (
  id_material INT PRIMARY KEY,
  autor VARCHAR(120),
  universidad VARCHAR(120),
  anio_grado YEAR,
  CONSTRAINT fk_tes_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE cd (
  id_material INT PRIMARY KEY,
  duracion_hor DECIMAL(5,2),
  formato_audio VARCHAR(40),
  CONSTRAINT fk_cd_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE dvd (
  id_material INT PRIMARY KEY,
  duracion_hor DECIMAL(5,2),
  universidad VARCHAR(120),
  anio_grado YEAR,
  CONSTRAINT fk_dvd_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE dispositivo_tecnologico (
  id_material INT PRIMARY KEY,
  marca VARCHAR(60),
  modelo VARCHAR(60),
  especificaciones TEXT,
  estado_inicial TEXT,
  CONSTRAINT fk_disp_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

CREATE TABLE juego_educativo (
  id_material INT PRIMARY KEY,
  area_tematica VARCHAR(120),
  tipo_juego VARCHAR(120),
  CONSTRAINT fk_jue_mat FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE
);

-- Autores N:M
CREATE TABLE autor (
  id_autor INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL
);

CREATE TABLE material_autor (
  id_material INT NOT NULL,
  id_autor INT NOT NULL,
  PRIMARY KEY (id_material, id_autor),
  FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material) ON DELETE CASCADE,
  FOREIGN KEY (id_autor) REFERENCES autor(id_autor) ON DELETE CASCADE
);

-- Ejemplares físicos
CREATE TABLE ejemplar_fisico (
  id_ejemplar INT PRIMARY KEY AUTO_INCREMENT,
  id_material INT NOT NULL,
  estado ENUM('disponible','reservado','prestado','mantenimiento','baja') DEFAULT 'disponible',
  ubicacion_fisica VARCHAR(120),
  cod_inv INT UNIQUE,
  FOREIGN KEY (id_material) REFERENCES material_bibliografico(id_material),
  INDEX idx_ej_estado (estado),
  INDEX idx_ej_material (id_material)
);

-- Usuarios
CREATE TABLE usuario (
  id_usuario INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  correo VARCHAR(120) UNIQUE NOT NULL,
  estado_cuenta ENUM('activo','inactivo','suspendido') DEFAULT 'activo',
  id_tipo_usuario INT NOT NULL,
  FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id_tipo_usuario)
);

-- Operaciones
CREATE TABLE reserva (
  id_reserva INT PRIMARY KEY AUTO_INCREMENT,
  id_ejemplar INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_reserva DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME NOT NULL,
  estado_reserva ENUM('activa','vencida','cancelada','atendida') DEFAULT 'activa',
  FOREIGN KEY (id_ejemplar) REFERENCES ejemplar_fisico(id_ejemplar),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  INDEX idx_reserva_usuario (id_usuario, estado_reserva)
);

CREATE TABLE prestamo (
  id_prestamo INT PRIMARY KEY AUTO_INCREMENT,
  id_ejemplar INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_prest DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_esperada DATETIME NOT NULL,
  fecha_dev DATETIME NULL,
  estado_dev BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (id_ejemplar) REFERENCES ejemplar_fisico(id_ejemplar),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  INDEX idx_prestamo_user (id_usuario, estado_dev)
);

CREATE TABLE multa (
  id_multa INT PRIMARY KEY AUTO_INCREMENT,
  id_prestamo INT NOT NULL UNIQUE,
  monto DECIMAL(8,2) NOT NULL,
  fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_pago DATETIME NULL,
  estado_multa ENUM('pendiente','pagada','anulada') DEFAULT 'pendiente',
  FOREIGN KEY (id_prestamo) REFERENCES prestamo(id_prestamo)
);

-- Auditoría
CREATE TABLE historial_accion (
  id_accion BIGINT PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  tipo_accion VARCHAR(60) NOT NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  descripcion VARCHAR(500),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  INDEX idx_hist_user_fecha (id_usuario, fecha_hora)
);
