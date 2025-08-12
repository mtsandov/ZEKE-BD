-- 05_seed.sql
USE bibliotrack;

INSERT INTO categoria (nombre, descripcion) VALUES
('Libro','Material impreso'), ('Revista','Publicación periódica'),
('Tesis','Trabajo de grado'), ('Multimedia','CD/DVD/Dispositivos'), ('Juego','Material lúdico');

INSERT INTO tipo_usuario (rol, permisos) VALUES
('admin', JSON_ARRAY('crud_all')),
('estudiante', JSON_ARRAY('reservar','prestar')),
('docente', JSON_ARRAY('reservar','prestar'));

INSERT INTO usuario (nombre, correo, id_tipo_usuario) VALUES
('Ana Torres','ana@demo.com',2),
('Luis Pérez','luis@demo.com',2),
('Admin','admin@demo.com',1);

INSERT INTO material_bibliografico (titulo, editorial, id_categoria, descripcion, anio_publicacion) VALUES
('Algoritmos y Estructuras','Prentice',1,'Libro de algoritmos',2019),
('Revista de Ciencia 2024','ACME',2,'Volumen temático',2024),
('Visión por Computador','Springer',1,'Fundamentos y aplicaciones',2021),
('Tesis IA en Educación','UCSG',3,'Análisis de impacto',2022);

-- Subtipos
INSERT INTO libro (id_material, isbn, edicion) VALUES
(1,'978-1-4028-9462-6','2da'),
(3,'978-3-540-79998-1','1ra');

INSERT INTO revista (id_material, issn, volumen, numero) VALUES
(2,'1234-5678','12','3');

INSERT INTO tesis (id_material, autor, universidad, anio_grado) VALUES
(4,'María León','UCSG',2022);

-- Autores
INSERT INTO autor (nombre) VALUES ('Robert Sedgewick'), ('Ian Goodfellow'), ('María León');
INSERT INTO material_autor (id_material,id_autor) VALUES
(1,1), (3,2), (4,3);

-- Ejemplares
INSERT INTO ejemplar_fisico (id_material, estado, ubicacion_fisica, cod_inv) VALUES
(1,'disponible','Estante A1',1001),
(1,'disponible','Estante A1',1002),
(2,'disponible','Hemeroteca',2001),
(3,'disponible','Estante B3',3001),
(4,'disponible','Tesisoteca',4001);

-- Reserva de Ana sobre ejemplar 1001 por 2 días
INSERT INTO reserva (id_ejemplar,id_usuario,fecha_reserva,fecha_expiracion,estado_reserva)
VALUES (1,1,NOW(), DATE_ADD(NOW(), INTERVAL 2 DAY), 'activa');

-- Préstamo de Luis sobre ejemplar 3001 (se hará vía SP en las pruebas del backend)
