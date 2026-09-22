-- Datos iniciales de desarrollo para Login
-- Password de todos los usuarios seed: Lumibell2026 (bcrypt, cost 10)
-- SOLO PARA DESARROLLO — no usar en produccion

-- Idempotente: puede ejecutarse múltiples veces (fresh init via docker-entrypoint y re-apply via scripts).
INSERT INTO sedes (nombre, direccion, latitud, longitud, radio_permitido_metros)
SELECT 'Sede Principal Lima', 'Av. Principal 123, Lima', -12.0463740, -77.0427930, 100.00
WHERE NOT EXISTS (SELECT 1 FROM sedes WHERE nombre = 'Sede Principal Lima');

INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
SELECT 'Luis', 'Bello', 'admin@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'ADMINISTRADOR'
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'admin@lumibell.com');
INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
SELECT 'Maria', 'Supervisor', 'supervisor@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'SUPERVISOR'
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'supervisor@lumibell.com');
INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
SELECT 'Carlos', 'Colaborador', 'colaborador@lumibell.com', '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'COLABORADOR'
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'colaborador@lumibell.com');

-- Empleados base: resuelve ids dinámicamente para ser idempotente incluso si IDs no son 1..3
INSERT INTO empleados (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, fecha_ingreso)
SELECT u.id, 'LUM-0001', 'Administrador de Sistemas', 'FULL_TIME', 'FIJO', (SELECT id FROM sedes WHERE nombre='Sede Principal Lima' LIMIT 1), '2024-01-15'
FROM usuarios u WHERE u.email='admin@lumibell.com'
AND NOT EXISTS (SELECT 1 FROM empleados WHERE codigo_empleado='LUM-0001');

INSERT INTO empleados (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, fecha_ingreso)
SELECT u.id, 'LUM-0002', 'Jefa de Estudio', 'FULL_TIME', 'FIJO', (SELECT id FROM sedes WHERE nombre='Sede Principal Lima' LIMIT 1), '2024-02-01'
FROM usuarios u WHERE u.email='supervisor@lumibell.com'
AND NOT EXISTS (SELECT 1 FROM empleados WHERE codigo_empleado='LUM-0002');

INSERT INTO empleados (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, fecha_ingreso)
SELECT u.id, 'LUM-0003', 'Colaborador de Produccion', 'PART_TIME', 'FLEXIBLE', (SELECT id FROM sedes WHERE nombre='Sede Principal Lima' LIMIT 1), '2024-03-10'
FROM usuarios u WHERE u.email='colaborador@lumibell.com'
AND NOT EXISTS (SELECT 1 FROM empleados WHERE codigo_empleado='LUM-0003');
