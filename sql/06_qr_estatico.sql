-- App Colaborador — QR estático (Semana 2, plan-semana-2 actividades 3-5)
-- Agrega sedes.qr_valor (formato LUMIBELL-SEDE-{id}-{8 hex}) + backfill de sedes existentes.
-- Decisiones que dejan obsoletos los comentarios de 04_marcaciones.sql:
-- - QR dinámico temporal de 2 min (crearQr/validarQr) se reemplaza por QR estático
--   comparado por igualdad exacta contra sedes.qr_valor en POST /api/marcaciones.
-- - GPS flexible (aceptar con fuera_radio=1) se reemplaza por rechazo 403 fuera de radio.
-- - Intentos rechazados no generan fila (ver plan-semana-2 §4).
-- Idempotente: ADD COLUMN falla si la columna ya existe; el UPDATE solo toca NULLs.

ALTER TABLE sedes ADD COLUMN qr_valor VARCHAR(100) NULL UNIQUE;

UPDATE sedes
SET qr_valor = CONCAT('LUMIBELL-SEDE-', id, '-', UPPER(SUBSTRING(MD5(RAND()), 1, 8)))
WHERE qr_valor IS NULL;
