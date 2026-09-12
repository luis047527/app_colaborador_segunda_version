-- App Colaborador — Marcaciones (Semana 2 base, decidido Semana 1)
-- Decisiones (docs/notes-david-sep-9.md):
-- - timestamp_utc DATETIME en UTC (hora oficial del servidor). fecha = jornada en
--   America/Lima derivada en API. Sin QR dinámico en MVP: QR estático `LUMIBELL-SEDE-{id}` (TODO dinámico).
-- - GPS flexible: se acepta y se marca fuera_radio (auditoría), no se rechaza.
-- - Se guardan intentos RECHAZADOs con motivo (trazabilidad piloto).
-- - Sin UNIQUE(empleado, fecha, tipo): convivien reintentos RECHAZADOs + 1 ACEPTADA.
--   Unicidad de "1 aceptada por tipo" se valida en API. Índice para lookup diario.

CREATE TABLE marcaciones (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empleado_id      BIGINT UNSIGNED NOT NULL,
  fecha            DATE            NOT NULL,
  tipo             VARCHAR(20)     NOT NULL,
  timestamp_utc    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sede_id          BIGINT UNSIGNED NULL,
  latitud          DECIMAL(10,7)   NULL,
  longitud         DECIMAL(10,7)   NULL,
  distancia_metros DECIMAL(10,2)   NULL,
  fuera_radio      TINYINT(1)      NOT NULL DEFAULT 0,
  resultado        VARCHAR(20)     NOT NULL DEFAULT 'ACEPTADA',
  motivo           VARCHAR(255)    NULL,
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_marcaciones_empleado_fecha (empleado_id, fecha),
  CONSTRAINT fk_marcaciones_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleados (id) ON DELETE RESTRICT,
  CONSTRAINT fk_marcaciones_sede FOREIGN KEY (sede_id)
    REFERENCES sedes (id) ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
