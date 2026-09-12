// Autorización por rol (el JWT ya prueba quién eres; esto prueba si puedes).
// Roles: ADMINISTRADOR > SUPERVISOR > COLABORADOR (ver Alcance §5.1).
function requerirRol(...roles) {
  return (req, res, next) => {
    if (req.usuario && roles.includes(req.usuario.rol)) return next();
    return res.status(403).json({ error: 'No autorizado' });
  };
}

// Como requerirRol, pero además deja pasar al dueño del recurso
// (:id de la ruta === sub del JWT). Para perfil propio.
function permitirPropio(...roles) {
  return (req, res, next) => {
    if (!req.usuario) return res.status(403).json({ error: 'No autorizado' });
    if (roles.includes(req.usuario.rol)) return next();
    if (Number(req.params.id) === req.usuario.sub) return next();
    return res.status(403).json({ error: 'No autorizado' });
  };
}

module.exports = { requerirRol, permitirPropio };
