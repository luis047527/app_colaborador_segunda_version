-- App Colaborador — Esquema para Inicio (Fase 2 / Modulo 2)
-- Basado en Handoff_Fase_2_Base_de_Datos_App_Colaborador_Lumibell.pdf
-- Tablas: marcaciones, balances_diarios, notificaciones

CREATE TABLE marcaciones (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empleado_id       BIGINT UNSIGNED NOT NULL,
  fecha_hora        DATETIME        NOT NULL,
  tipo_marcacion    VARCHAR(30)     NOT NULL,
  metodo_marcacion  VARCHAR(30)     NOT NULL,
  sede_id           BIGINT UNSIGNED NULL,
  latitud           DECIMAL(10,7)   NULL,
  longitud          DECIMAL(10,7)   NULL,
  precision_gps     DECIMAL(8,2)    NULL,
  foto_url          VARCHAR(500)    NULL,
  qr_codigo         VARCHAR(255)    NULL,
  dispositivo       VARCHAR(255)    NULL,
  ip                VARCHAR(45)     NULL,
  conexion          VARCHAR(30)     NULL,
  estado            VARCHAR(20)     NOT NULL DEFAULT 'VALIDA',
  motivo_rechazo    VARCHAR(255)    NULL,
  created_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_marcaciones_empleado (empleado_id),
  KEY idx_marcaciones_sede (sede_id),
  KEY idx_marcaciones_fecha_hora (fecha_hora),
  KEY idx_marcaciones_empleado_fecha (empleado_id, fecha_hora),
  CONSTRAINT fk_marcaciones_empleado FOREIGN KEY (empleado_id) REFERENCES empleados (id) ON DELETE RESTRICT,
  CONSTRAINT fk_marcaciones_sede FOREIGN KEY (sede_id) REFERENCES sedes (id) ON DELETE RESTRICT,
  CONSTRAINT chk_marcaciones_tipo CHECK (tipo_marcacion IN ('ENTRADA','SALIDA','SALIDA_ALMUERZO','REGRESO_ALMUERZO','SALIDA_PERMISO','REGRESO_PERMISO')),
  CONSTRAINT chk_marcaciones_metodo CHECK (metodo_marcacion IN ('QR','GPS_FOTO')),
  CONSTRAINT chk_marcaciones_estado CHECK (estado IN ('VALIDA','RECHAZADA')),
  CONSTRAINT chk_marcaciones_conexion CHECK (conexion IS NULL OR conexion IN ('WIFI','DATOS','OFFLINE'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE balances_diarios (
  id                          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  empleado_id                 BIGINT UNSIGNED NOT NULL,
  fecha                       DATE            NOT NULL,
  jornada_requerida_minutos   INT             NOT NULL DEFAULT 0,
  minutos_trabajados          INT             NOT NULL DEFAULT 0,
  minutos_refrigerio          INT             NOT NULL DEFAULT 0,
  minutos_permiso             INT             NOT NULL DEFAULT 0,
  balance_minutos             INT             NOT NULL DEFAULT 0,
  tardanza_minutos            INT             NOT NULL DEFAULT 0,
  horas_extra_minutos         INT             NOT NULL DEFAULT 0,
  estado_jornada              VARCHAR(30)     NOT NULL DEFAULT 'PENDIENTE',
  updated_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_balances_empleado_fecha (empleado_id, fecha),
  KEY idx_balances_fecha (fecha),
  CONSTRAINT fk_balances_empleado FOREIGN KEY (empleado_id) REFERENCES empleados (id) ON DELETE RESTRICT,
  CONSTRAINT chk_balances_estado CHECK (estado_jornada IN ('PENDIENTE','COMPLETA','INCOMPLETA','CON_TARDANZA','HORAS_EXTRA','PERMISO_APROBADO','VACACIONES'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE notificaciones (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id      BIGINT UNSIGNED NOT NULL,
  tipo            VARCHAR(30)     NOT NULL,
  titulo          VARCHAR(150)    NOT NULL,
  mensaje         TEXT            NOT NULL,
  leida           TINYINT(1)      NOT NULL DEFAULT 0,
  fecha_lectura   DATETIME        NULL,
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notif_usuario (usuario_id),
  KEY idx_notif_leida (leida),
  KEY idx_notif_created (created_at),
  CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT chk_notif_tipo CHECK (tipo IN ('ASISTENCIA','SOLICITUD','APROBACION','SISTEMA','RECORDATORIO'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
