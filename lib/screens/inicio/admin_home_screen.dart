import 'package:flutter/material.dart';

import '../../models/usuario.dart';

/// Pantalla principal para ADMINISTRADOR.
///
/// La identidad del administrador procede de la sesión ya autenticada. Los
/// indicadores de equipo se reemplazarán por la respuesta del dashboard
/// administrativo cuando la API exponga ese recurso.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.usuario, required this.onLogout});

  final Usuario usuario;
  final VoidCallback onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const _navy = Color(0xFF0B1D47);
  static const _brown = Color(0xFF843816);
  static const _softBrown = Color(0xFFFFEEE5);
  static const _canvas = Color(0xFFFFFCF9);
  static const _muted = Color(0xFF59708E);
  int _selectedTab = 0;

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title estará disponible en el siguiente paso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatFullDate(DateTime.now());
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),
                        const SizedBox(height: 24),
                        _studioBanner(),
                        const SizedBox(height: 22),
                        _sectionTitle('Resumen del equipo', action: 'Ver todos'),
                        const SizedBox(height: 12),
                        _summaryGrid(),
                        const SizedBox(height: 24),
                        _sectionTitle('Accesos rápidos'),
                        const SizedBox(height: 12),
                        _quickAccessGrid(),
                        const SizedBox(height: 24),
                        _sectionTitle('Actividad reciente', action: 'Ver más'),
                        const SizedBox(height: 12),
                        _recentActivity(),
                        const SizedBox(height: 6),
                        Text(
                          _capitalize(date),
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          _avatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Hola, ${widget.usuario.nombre}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text('Administrador', style: TextStyle(color: _muted, fontSize: 17)),
              const SizedBox(height: 3),
              const Text('Gestiona tu equipo con eficiencia',
                  style: TextStyle(color: _muted, fontSize: 14)),
            ]),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onLogout,
            icon: const Badge(
              smallSize: 9,
              backgroundColor: Color(0xFFFF4D57),
              child: Icon(Icons.notifications_none_rounded, color: _navy, size: 29),
            ),
          ),
        ],
      );

  Widget _avatar() {
    final initials = '${widget.usuario.nombre.characters.first}${widget.usuario.apellido.characters.first}'
        .toUpperCase();
    return CircleAvatar(
      radius: 34,
      backgroundColor: const Color(0xFFF2E8E2),
      foregroundImage: widget.usuario.fotoUrl == null ? null : NetworkImage(widget.usuario.fotoUrl!),
      child: Text(initials,
          style: const TextStyle(color: _brown, fontWeight: FontWeight.w800, fontSize: 20)),
    );
  }

  Widget _studioBanner() => Container(
        height: 145,
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D4B3D), Color(0xFFB18B72)],
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: -12,
            bottom: -28,
            child: Icon(Icons.photo_camera_outlined,
                size: 128, color: Colors.white.withValues(alpha: .20)),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Juntos hacemos',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              Text('que cada día cuente',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              SizedBox(height: 13),
              Text('LUMIBELL  STUDIOS',
                  style: TextStyle(color: Colors.white, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
            ],
          ),
        ]),
      );

  Widget _sectionTitle(String title, {String? action}) => Row(children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        if (action != null)
          TextButton(
            onPressed: () => _showComingSoon(action),
            child: Text('$action  ›', style: const TextStyle(color: _muted)),
          ),
      ]);

  Widget _summaryGrid() => GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _SummaryCard('6', 'Colaboradores', Icons.groups_rounded, Color(0xFFEAF2FF), Color(0xFF2775EF)),
          _SummaryCard('5', 'Activos', Icons.person_rounded, Color(0xFFE7FAF2), Color(0xFF18A66B)),
          _SummaryCard('1', 'Inactivos', Icons.access_time_filled_rounded, Color(0xFFFFEEEE), Color(0xFFE74A49)),
          _SummaryCard('6', 'Con horario', Icons.calendar_month_rounded, Color(0xFFF3EDFF), Color(0xFF8059D8)),
        ],
      );

  Widget _quickAccessGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.44,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _QuickAccessCard('Colaboradores', 'Crear y gestionar usuarios', Icons.groups_rounded,
              const Color(0xFFEAF2FF), () => _showComingSoon('Colaboradores')),
          _QuickAccessCard('Horarios', 'Crear y asignar horarios', Icons.calendar_month_rounded,
              const Color(0xFFFFEEE5), () => _showComingSoon('Horarios')),
          _QuickAccessCard('Asistencias', 'Ver marcaciones del equipo', Icons.schedule_rounded,
              const Color(0xFFEAF2FF), () => _showComingSoon('Asistencias')),
          _QuickAccessCard('Reportes', 'Consultar asistencias', Icons.bar_chart_rounded,
              const Color(0xFFFFEEEE), () => _showComingSoon('Reportes')),
        ],
      );

  Widget _recentActivity() => const Column(children: [
        _ActivityItem(Icons.person_add_alt_1_rounded, Color(0xFFE5F9EF), 'Nuevo colaborador registrado', 'Carlos Ramírez', '10:24 a. m.'),
        SizedBox(height: 9),
        _ActivityItem(Icons.calendar_month_rounded, Color(0xFFEAF2FF), 'Horario actualizado', 'María Cordero', '09:18 a. m.'),
        SizedBox(height: 9),
        _ActivityItem(Icons.schedule_rounded, Color(0xFFEAF2FF), 'Marcación registrada', 'Luis Castillo', '08:57 a. m.'),
      ]);

  Widget _bottomNavigation() {
    const destinations = [
      (Icons.home_outlined, 'Inicio'),
      (Icons.groups_outlined, 'Colaboradores'),
      (Icons.calendar_month_outlined, 'Horarios'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0E9E4))),
        ),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final selected = index == _selectedTab;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  setState(() => _selectedTab = index);
                  if (index != 0) _showComingSoon(destination.$2);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _softBrown : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(destination.$1, color: selected ? _brown : _navy),
                    const SizedBox(height: 3),
                    Text(destination.$2,
                        style: TextStyle(
                            color: selected ? _brown : _navy,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _capitalize(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.value, this.label, this.icon, this.background, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF0B1D47))),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF29415F))),
        ]),
      );
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard(this.title, this.subtitle, this.icon, this.iconBackground, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFF0EBE7)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: const Color(0xFF843816)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Color(0xFF0B1D47), fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF59708E), fontSize: 11.5)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF0B1D47)),
            ]),
          ),
        ),
      );
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem(this.icon, this.background, this.title, this.subtitle, this.time);
  final IconData icon;
  final Color background;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFF0EBE7)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF16714D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFF0B1D47), fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF59708E), fontSize: 13)),
          ])),
          Text(time, style: const TextStyle(color: Color(0xFF59708E), fontSize: 12)),
        ]),
      );
}
