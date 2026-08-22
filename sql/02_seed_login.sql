-- Datos iniciales de desarrollo para Login
-- Password de todos los usuarios seed: Lumibell2026 (bcrypt, cost 10)
-- SOLO PARA DESARROLLO — no usar en produccion

INSERT INTO sedes (nombre, direccion, latitud, longitud, radio_permitido_metros) VALUES
  ('Sede Principal Lima', 'Av. Principal 123, Lima', -12.0463740, -77.0427930, 100.00);

INSERT INTO usuarios (nombre, apellido, email, password_hash, rol) VALUES
  ('Luis', 'Bello', 'admin@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'ADMINISTRADOR'),
  ('Maria', 'Supervisor', 'supervisor@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'SUPERVISOR'),
  ('Carlos', 'Colaborador', 'colaborador@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'COLABORADOR');

INSERT INTO empleados (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, fecha_ingreso) VALUES
  (1, 'LUM-0001', 'Administrador de Sistemas', 'FULL_TIME', 'FIJO', 1, '2024-01-15'),
  (2, 'LUM-0002', 'Jefa de Estudio', 'FULL_TIME', 'FIJO', 1, '2024-02-01'),
  (3, 'LUM-0003', 'Colaborador de Produccion', 'PART_TIME', 'FLEXIBLE', 1, '2024-03-10');
