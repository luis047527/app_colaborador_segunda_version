-- App Colaborador — Horarios personalizados (Fase MVP)
-- 2 tables: horarios (header) + horario_dias (7 rows per horario, dia 1=Lun..7=Dom ISO)
-- Assignment: empleados.horario_id FK NULL (one horario per empleado, NULL = unassigned)
-- MVP rules (API-only, no CHECKs): dia 1-7, salida > entrada (no overnight),
-- entrada <= ref_ini < ref_fin <= salida. Calc clamps early arrival to programada.

CREATE TABLE horarios (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre             VARCHAR(100)    NOT NULL,
  descripcion        VARCHAR(255)    NULL,
  tolerancia_minutos SMALLINT UNSIGNED NOT NULL DEFAULT 10,
  vigencia_desde     DATE            NOT NULL,
  vigencia_hasta     DATE            NULL,
  created_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE horario_dias (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  horario_id  BIGINT UNSIGNED NOT NULL,
  dia_semana  TINYINT UNSIGNED NOT NULL,
  entrada     TIME            NULL,
  ref_inicio  TIME            NULL,
  ref_fin     TIME            NULL,
  salida      TIME            NULL,
  es_descanso TINYINT(1)      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_horario_dia (horario_id, dia_semana),
  CONSTRAINT fk_dias_horario FOREIGN KEY (horario_id)
    REFERENCES horarios (id) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

ALTER TABLE empleados
  ADD COLUMN horario_id BIGINT UNSIGNED NULL AFTER sede_id,
  ADD CONSTRAINT fk_empleados_horario FOREIGN KEY (horario_id)
    REFERENCES horarios (id) ON DELETE RESTRICT;
