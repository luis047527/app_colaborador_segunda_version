-- Datos de demostración para los flujos móviles del colaborador.
-- Password de los usuarios creados: Lumibell2026
-- Script idempotente: puede ejecutarse más de una vez.

INSERT INTO horarios (nombre, descripcion, tolerancia_minutos, vigencia_desde)
SELECT 'Horario Oficina 08:00 - 17:00', 'Jornada administrativa de lunes a viernes', 10, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM horarios WHERE nombre = 'Horario Oficina 08:00 - 17:00');

SET @horario_oficina = (
  SELECT id FROM horarios WHERE nombre = 'Horario Oficina 08:00 - 17:00' ORDER BY id LIMIT 1
);

INSERT INTO horario_dias
  (horario_id, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso)
SELECT @horario_oficina, dias.dia, dias.entrada, dias.ref_inicio, dias.ref_fin, dias.salida, dias.descanso
FROM (
  SELECT 1 dia, '08:00:00' entrada, '13:00:00' ref_inicio, '14:00:00' ref_fin, '17:00:00' salida, 0 descanso
  UNION ALL SELECT 2, '08:00:00', '13:00:00', '14:00:00', '17:00:00', 0
  UNION ALL SELECT 3, '08:00:00', '13:00:00', '14:00:00', '17:00:00', 0
  UNION ALL SELECT 4, '08:00:00', '13:00:00', '14:00:00', '17:00:00', 0
  UNION ALL SELECT 5, '08:00:00', '13:00:00', '14:00:00', '17:00:00', 0
  UNION ALL SELECT 6, NULL, NULL, NULL, NULL, 1
  UNION ALL SELECT 7, NULL, NULL, NULL, NULL, 1
) AS dias
WHERE NOT EXISTS (SELECT 1 FROM horario_dias WHERE horario_id = @horario_oficina);

INSERT INTO horarios (nombre, descripcion, tolerancia_minutos, vigencia_desde)
SELECT 'Horario Part Time 09:00 - 14:00', 'Jornada parcial de lunes a viernes', 5, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM horarios WHERE nombre = 'Horario Part Time 09:00 - 14:00');

SET @horario_part_time = (
  SELECT id FROM horarios WHERE nombre = 'Horario Part Time 09:00 - 14:00' ORDER BY id LIMIT 1
);

INSERT INTO horario_dias
  (horario_id, dia_semana, entrada, ref_inicio, ref_fin, salida, es_descanso)
SELECT @horario_part_time, dias.dia, dias.entrada, NULL, NULL, dias.salida, dias.descanso
FROM (
  SELECT 1 dia, '09:00:00' entrada, '14:00:00' salida, 0 descanso
  UNION ALL SELECT 2, '09:00:00', '14:00:00', 0
  UNION ALL SELECT 3, '09:00:00', '14:00:00', 0
  UNION ALL SELECT 4, '09:00:00', '14:00:00', 0
  UNION ALL SELECT 5, '09:00:00', '14:00:00', 0
  UNION ALL SELECT 6, NULL, NULL, 1
  UNION ALL SELECT 7, NULL, NULL, 1
) AS dias
WHERE NOT EXISTS (SELECT 1 FROM horario_dias WHERE horario_id = @horario_part_time);

INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
SELECT 'Ana', 'Torres', 'ana.torres@lumibell.com',
  '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'COLABORADOR'
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'ana.torres@lumibell.com');

INSERT INTO usuarios (nombre, apellido, email, password_hash, rol)
SELECT 'Juan', 'Pérez', 'juan.perez@lumibell.com',
  '$2b$10$N6GVBuIuH/A96z7y7qpSzOEVDBXOzaiJ5JZc4fwhQ8G492Ce.UY1C', 'COLABORADOR'
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'juan.perez@lumibell.com');

SET @sede_principal = (SELECT id FROM sedes ORDER BY id LIMIT 1);
SET @usuario_ana = (SELECT id FROM usuarios WHERE email = 'ana.torres@lumibell.com');
SET @usuario_juan = (SELECT id FROM usuarios WHERE email = 'juan.perez@lumibell.com');

INSERT INTO empleados
  (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, horario_id, fecha_ingreso)
SELECT @usuario_ana, 'LUM-0004', 'Asistente de Produccion', 'FULL_TIME', 'FIJO',
  @sede_principal, @horario_oficina, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM empleados WHERE usuario_id = @usuario_ana);

INSERT INTO empleados
  (usuario_id, codigo_empleado, cargo, modalidad_laboral, tipo_horario, sede_id, horario_id, fecha_ingreso)
SELECT @usuario_juan, 'LUM-0005', 'Editor Fotografico', 'FULL_TIME', 'FIJO',
  @sede_principal, @horario_oficina, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM empleados WHERE usuario_id = @usuario_juan);

UPDATE empleados
SET horario_id = @horario_part_time, tipo_horario = 'FIJO'
WHERE usuario_id = (SELECT id FROM usuarios WHERE email = 'colaborador@lumibell.com');

-- Historial de demostración para Carlos: una jornada completa y una incompleta.
SET @empleado_carlos = (
  SELECT e.id FROM empleados e
  JOIN usuarios u ON u.id = e.usuario_id
  WHERE u.email = 'colaborador@lumibell.com'
);

INSERT INTO marcaciones
  (empleado_id, fecha, tipo, timestamp_utc, sede_id, resultado, fuera_radio)
SELECT @empleado_carlos, DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY), datos.tipo,
  DATE_ADD(DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY), INTERVAL datos.hora HOUR),
  @sede_principal, 'ACEPTADA', 0
FROM (
  SELECT 'ENTRADA' tipo, 14 hora
  UNION ALL SELECT 'SALIDA_REFRIGERIO', 18
  UNION ALL SELECT 'REGRESO_REFRIGERIO', 19
  UNION ALL SELECT 'SALIDA', 23
) AS datos
WHERE NOT EXISTS (
  SELECT 1 FROM marcaciones
  WHERE empleado_id = @empleado_carlos
    AND fecha = DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)
);

INSERT INTO marcaciones
  (empleado_id, fecha, tipo, timestamp_utc, sede_id, resultado, fuera_radio)
SELECT @empleado_carlos, DATE_SUB(CURRENT_DATE, INTERVAL 2 DAY), 'ENTRADA',
  DATE_ADD(DATE_SUB(CURRENT_DATE, INTERVAL 2 DAY), INTERVAL 14 HOUR),
  @sede_principal, 'ACEPTADA', 0
WHERE NOT EXISTS (
  SELECT 1 FROM marcaciones
  WHERE empleado_id = @empleado_carlos
    AND fecha = DATE_SUB(CURRENT_DATE, INTERVAL 2 DAY)
);
