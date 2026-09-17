import 'package:flutter/material.dart';

import '../theme/lumibell_theme.dart';

class LumibellLogo extends StatelessWidget {
  const LumibellLogo({super.key, this.height = 76});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: height * 2.65,
    child: ClipRect(
      child: Image.asset(
        'assets/images/logo_lumibell.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        semanticLabel: 'Lumibell Studios',
      ),
    ),
  );
}

class LumibellCard extends StatelessWidget {
  const LumibellCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(LumibellRadii.lg),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumibellRadii.lg),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LumibellRadii.lg),
          border: Border.all(color: LumibellColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0D102650), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: child,
      ),
    ),
  );
}

class LumibellSectionTitle extends StatelessWidget {
  const LumibellSectionTitle({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
    if (action != null)
      TextButton(
        onPressed: onAction,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(action!, style: const TextStyle(color: LumibellColors.navySoft, fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, size: 19, color: LumibellColors.navySoft),
        ]),
      ),
  ]);
}

class LumibellStatusChip extends StatelessWidget {
  const LumibellStatusChip({super.key, required this.label, required this.color, required this.background});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class LumibellStateView extends StatelessWidget {
  const LumibellStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: LumibellColors.peachSoft, shape: BoxShape.circle),
          child: Icon(icon, color: LumibellColors.copper, size: 42),
        ),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        if (actionLabel != null) ...[
          const SizedBox(height: 22),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    ),
  );
}

class LumibellLoadingView extends StatelessWidget {
  const LumibellLoadingView({super.key, this.message = 'Cargando información...'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: LumibellColors.copper),
      const SizedBox(height: 16),
      Text(message, style: Theme.of(context).textTheme.bodyMedium),
    ]),
  );
}

