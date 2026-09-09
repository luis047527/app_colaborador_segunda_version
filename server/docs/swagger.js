// Spec OpenAPI generada desde JSDoc (@openapi) en routes/*.js + index.js.
// UI: GET /api-docs · JSON crudo (para codegen Flutter): GET /api-docs.json
const path = require('node:path');
const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'App Colaborador API (Lumibell MVP)',
      version: '1.0.0',
      description:
        'Autenticación, colaboradores, sedes, horarios y marcaciones. ' +
        'Validaciones de negocio en API (sin CHECKs enum en DB). JWT en `Authorization: Bearer`.',
    },
    servers: [{ url: 'http://localhost:3000' }],
    security: [{ bearerAuth: [] }],
    components: {
      securitySchemes: {
        bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: { error: { type: 'string' } },
        },
        LoginInput: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: { type: 'string', example: 'admin@lumibell.com' },
            password: { type: 'string', example: 'Lumibell2026' },
          },
        },
        Usuario: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            nombre: { type: 'string' },
            apellido: { type: 'string' },
            email: { type: 'string' },
            foto_url: { type: 'string', nullable: true },
            rol: { type: 'string', enum: ['ADMINISTRADOR', 'SUPERVISOR', 'COLABORADOR'] },
            estado: { type: 'string', enum: ['ACTIVO', 'INACTIVO', 'BLOQUEADO'] },
            ultimo_acceso: { type: 'string', nullable: true },
            created_at: { type: 'string' },
            updated_at: { type: 'string' },
          },
        },
        UsuarioInput: {
          type: 'object',
          required: ['nombre', 'apellido', 'email', 'password', 'rol'],
          properties: {
            nombre: { type: 'string' },
            apellido: { type: 'string' },
            email: { type: 'string' },
            password: { type: 'string' },
            rol: { type: 'string', enum: ['ADMINISTRADOR', 'SUPERVISOR', 'COLABORADOR'] },
            foto_url: { type: 'string' },
          },
        },
        Empleado: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            usuario_id: { type: 'integer' },
            codigo_empleado: { type: 'string', example: 'LUM-0004' },
            cargo: { type: 'string' },
            modalidad_laboral: { type: 'string', enum: ['FULL_TIME', 'PART_TIME'] },
            tipo_horario: { type: 'string', enum: ['FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO'] },
            sede_id: { type: 'integer', nullable: true },
            horario_id: { type: 'integer', nullable: true },
            fecha_ingreso: { type: 'string', format: 'date' },
            fecha_cese: { type: 'string', format: 'date', nullable: true },
            estado: { type: 'string', enum: ['ACTIVO', 'INACTIVO'] },
          },
        },
        EmpleadoInput: {
          type: 'object',
          required: [
            'usuario_id',
            'codigo_empleado',
            'cargo',
            'modalidad_laboral',
            'tipo_horario',
            'fecha_ingreso',
          ],
          properties: {
            usuario_id: { type: 'integer' },
            codigo_empleado: { type: 'string' },
            cargo: { type: 'string' },
            modalidad_laboral: { type: 'string', enum: ['FULL_TIME', 'PART_TIME'] },
            tipo_horario: { type: 'string', enum: ['FIJO', 'FLEXIBLE', 'ROTATIVO', 'PERSONALIZADO'] },
            sede_id: { type: 'integer' },
            horario_id: { type: 'integer' },
            fecha_ingreso: { type: 'string', format: 'date' },
            fecha_cese: { type: 'string', format: 'date' },
            estado: { type: 'string', enum: ['ACTIVO', 'INACTIVO'] },
          },
        },
        Sede: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            nombre: { type: 'string' },
            direccion: { type: 'string' },
            latitud: { type: 'number' },
            longitud: { type: 'number' },
            radio_permitido_metros: { type: 'number' },
            estado: { type: 'string', enum: ['ACTIVA', 'INACTIVA'] },
          },
        },
        SedeInput: {
          type: 'object',
          required: ['nombre', 'direccion', 'latitud', 'longitud', 'radio_permitido_metros'],
          properties: {
            nombre: { type: 'string' },
            direccion: { type: 'string' },
            latitud: { type: 'number', minimum: -90, maximum: 90 },
            longitud: { type: 'number', minimum: -180, maximum: 180 },
            radio_permitido_metros: { type: 'number', exclusiveMinimum: 0 },
            estado: { type: 'string', enum: ['ACTIVA', 'INACTIVA'] },
          },
        },
        HorarioDiaInput: {
          type: 'object',
          required: ['dia_semana'],
          properties: {
            dia_semana: { type: 'integer', minimum: 1, maximum: 7, description: '1=Lun … 7=Dom' },
            entrada: { type: 'string', example: '10:00', nullable: true },
            ref_inicio: { type: 'string', nullable: true },
            ref_fin: { type: 'string', nullable: true },
            salida: { type: 'string', example: '19:00', nullable: true },
            es_descanso: { type: 'boolean', default: false },
          },
        },
        HorarioInput: {
          type: 'object',
          required: ['nombre', 'vigencia_desde', 'dias'],
          properties: {
            nombre: { type: 'string' },
            descripcion: { type: 'string' },
            tolerancia_minutos: { type: 'integer', minimum: 0, maximum: 180, default: 10 },
            vigencia_desde: { type: 'string', format: 'date' },
            vigencia_hasta: { type: 'string', format: 'date', nullable: true },
            dias: {
              type: 'array',
              minItems: 7,
              maxItems: 7,
              items: { $ref: '#/components/schemas/HorarioDiaInput' },
            },
          },
        },
      },
    },
  },
  apis: [path.join(__dirname, '..', 'index.js'), path.join(__dirname, '..', 'routes', '*.js')],
};

module.exports = swaggerJSDoc(options);
