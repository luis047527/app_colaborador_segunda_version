-- App Colaborador — Esquema para Login (Fase 2)
-- Basado en Handoff_Fase_2_Base_de_Datos_App_Colaborador_Lumibell.pdf
-- Tablas: usuarios, sedes, empleados (soporte para post-login)

CREATE TABLE usuarios (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(100)    NOT NULL,
  apellido      VARCHAR(100)    NOT NULL,
  email         VARCHAR(150)    NOT NULL,
  password_hash VARCHAR(255)    NOT NULL,
  foto_url      VARCHAR(500)    NULL,
  rol           VARCHAR(20)     NOT NULL,
  estado        VARCHAR(20)     NOT NULL DEFAULT 'ACTIVO',
  ultimo_acceso DATETIME        NULL,
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_email (email),
  KEY idx_usuarios_estado (estado),
  CONSTRAINT chk_usuarios_rol CHECK (rol IN ('ADMINISTRADOR', 'SUPERVISOR', 'COLABORADOR')),
  CONSTRAINT chk_usuarios_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'BLOQUEADO'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE sedes (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre                 VARCHAR(100)    NOT NULL,
  direccion              VARCHAR(255)    NOT NULL,
  latitud                DECIMAL(10,7)   NOT NULL,
  longitud               DECIMAL(10,7)   NOT NULL,
  radio_permitido_metros DECIMAL(8,2)    NOT NULL,
  estado                 VARCHAR(20)     NOT NULL DEFAULT 'ACTIVA',
  created_at             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT chk_sedes_estado CHECK (estado IN ('ACTIVA', 'INACTIVA'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE empleados (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id        BIGINT UNSIGNED NOT NULL,
  codigo_empleado   VARCHAR(30)     NOT NULL,
  cargo             VARCHAR(100)    NOT NULL,
  modalidad_laboral VARCHAR(30)     NOT NULL,
  tipo_horario      VARCHAR(30)     NOT NULL,
  sede_id           BIGINT UNSIGNED NULL,
  fecha_ingreso     DATE            NOT NULL,
  fecha_cese        DATE            NULL,
  estado            VARCHAR(20)     NOT NULL DEFAULT 'ACTIVO',
  created_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_empleados_usuario (usuario_id),
  UNIQUE KEY uq_empleados_codigo (codigo_empleado),
  KEY idx_empleados_sede (sede_id),
  KEY idx_empleados_estado (estado),
  CONSTRAINT fk_empleados_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT,
  CONSTRAINT fk_empleados_sede FOREIGN KEY (sede_id) REFERENCES sedes (id) ON DELETE RESTRICT,
  CONSTRAINT chk_empleados_tipo_horario CHECK (tipo_horario IN ('FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO')),
  CONSTRAINT chk_empleados_estado CHECK (estado IN ('ACTIVO', 'INACTIVO')),
  CONSTRAINT chk_empleados_fechas CHECK (fecha_cese IS NULL OR fecha_cese >= fecha_ingreso)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
