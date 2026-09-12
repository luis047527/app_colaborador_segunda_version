// Helpers de fecha/hora para jornada laboral.
// Hora oficial: UTC en DB; fecha de jornada: America/Lima (ver reglas_calculo.md §1).
function fechaLimaYMD(date = new Date()) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Lima',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date); // YYYY-MM-DD
}

// 1=Lun … 7=Dom (ISO). No usar DAYOFWEEK() (USA 1=Dom).
function diaSemanaLima(date = new Date()) {
  const wd = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/Lima',
    weekday: 'short',
  }).format(date);
  return { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 }[wd];
}

// 'HH:MM:SS' -> minutos enteros. null -> null.
function minutosDesdeHora(t) {
  if (!t) return null;
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
}

module.exports = { fechaLimaYMD, diaSemanaLima, minutosDesdeHora };
