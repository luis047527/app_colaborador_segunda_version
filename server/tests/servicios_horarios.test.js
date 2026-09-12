// Unit tests del servicio de horarios: funciones puras, sin app ni DB.
// Ejecutar: npm test -- tests/servicios_horarios.test.js
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { normalizarHora, validarDias, crearHorario } = require('../services/horarios');

const dia = (dia_semana, entrada = '10:00', refI = '13:00', refF = '14:00', salida = '19:00') => ({
  dia_semana,
  entrada,
  ref_inicio: refI,
  ref_fin: refF,
  salida,
  es_descanso: 0,
});
const semana = () => [
  ...[1, 2, 3, 4, 5, 6].map((d) => dia(d)),
  { dia_semana: 7, entrada: null, ref_inicio: null, ref_fin: null, salida: null, es_descanso: 1 },
];

describe('normalizarHora', () => {
  it('normaliza y valida', async () => {
    assert.equal(normalizarHora('9:05'), '09:05:00');
    assert.equal(normalizarHora('10:00:00'), '10:00:00');
    assert.equal(normalizarHora(null), null);
    assert.equal(normalizarHora(''), null);
    assert.equal(normalizarHora('abc'), undefined);
    assert.equal(normalizarHora('25:00'), undefined);
    assert.equal(normalizarHora('10:60'), undefined);
  });
});

describe('validarDias', () => {
  it('semana válida deja _norm', async () => {
    const dias = semana();
    assert.equal(validarDias(dias), null);
    assert.deepEqual(dias[0]._norm, {
      entrada: '10:00:00',
      ref_inicio: '13:00:00',
      ref_fin: '14:00:00',
      salida: '19:00:00',
      es_descanso: 0,
    });
    assert.deepEqual(dias[6]._norm, {
      entrada: null,
      ref_inicio: null,
      ref_fin: null,
      salida: null,
      es_descanso: 1,
    });
  });

  it('rechaza estructura inválida', async () => {
    assert.match(validarDias(semana().slice(0, 6)), /7 filas/);
    assert.match(validarDias('x'), /7 filas/);
    const dup = semana();
    dup[1] = { ...dup[1], dia_semana: 1 };
    assert.match(validarDias(dup), /duplicado/);
    const fuera = semana();
    fuera[0] = { ...fuera[0], dia_semana: 8 };
    assert.match(validarDias(fuera), /1-7/);
  });

  it('rechaza overnight, refs y horas', async () => {
    const noche = semana();
    noche[0] = dia(1, '23:00', null, null, '07:00');
    assert.match(validarDias(noche), /nocturno/);

    const medias = semana();
    medias[0] = dia(1, '10:00', '13:00', null, '19:00');
    assert.match(validarDias(medias), /juntos/);

    const desorden = semana();
    desorden[0] = dia(1, '10:00', '15:00', '14:00', '19:00');
    assert.match(validarDias(desorden), /orden/);

    const mala = semana();
    mala[0] = dia(1, 'abc', null, null, '19:00');
    assert.match(validarDias(mala), /inválida/);

    const sinSalida = semana();
    sinSalida[0] = dia(1, '10:00', null, null, null);
    assert.match(validarDias(sinSalida), /obligatorias/);
  });
});

describe('crearHorario', () => {
  const tx = { begun: false, committed: false, rolledBack: false, released: false };
  let diasInsertados = 0;
  let fallaEn = -1;

  const poolStub = {
    async getConnection() {
      return {
        async beginTransaction() {
          tx.begun = true;
        },
        async commit() {
          tx.committed = true;
        },
        async rollback() {
          tx.rolledBack = true;
        },
        async release() {
          tx.released = true;
        },
        async query(sql) {
          if (sql.startsWith('INSERT INTO horarios')) return [{ insertId: 50 }];
          if (sql.startsWith('INSERT INTO horario_dias')) {
            diasInsertados += 1;
            if (diasInsertados === fallaEn) throw new Error('boom');
            return [{ insertId: 100 + diasInsertados }];
          }
          throw new Error(`query no mockeada: ${sql}`);
        },
      };
    },
  };

  const datos = () => {
    const dias = semana();
    assert.equal(validarDias(dias), null);
    return {
      nombre: 'FULL_TIME',
      descripcion: null,
      tolerancia: 10,
      vigencia_desde: '2026-01-01',
      vigencia_hasta: null,
      dias,
    };
  };

  it('201 commit + release con 7 dias', async () => {
    tx.begun = tx.committed = tx.rolledBack = tx.released = false;
    diasInsertados = 0;
    fallaEn = -1;
    const r = await crearHorario(poolStub, datos());
    assert.equal(r.status, 201);
    assert.equal(r.data.id, 50);
    assert.equal(r.data.dias.length, 7);
    assert.equal(tx.begun && tx.committed && tx.released, true);
    assert.equal(tx.rolledBack, false);
    assert.equal(diasInsertados, 7);
  });

  it('rollback + release y propaga', async () => {
    tx.begun = tx.committed = tx.rolledBack = tx.released = false;
    diasInsertados = 0;
    fallaEn = 3;
    await assert.rejects(crearHorario(poolStub, datos()));
    assert.equal(tx.committed, false);
    assert.equal(tx.rolledBack && tx.released, true);
  });
});
