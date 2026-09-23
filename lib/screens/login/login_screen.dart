import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/lumibell_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _brown = Color(0xFF5A3024);
  static const _darkBrown = Color(0xFF3F2924);
  static const _peach = Color(0xFFF4D9C0);
  static const _lightPeach = Color(0xFFF9E9DD);
  static const _cream = Color(0xFFFBF7F3);
  static const _warmGrey = Color(0xFF7D706B);
  static const _coral = Color(0xFFD85C4F);
  static const _border = Color(0xFFEAD8CC);

  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authService.login(
        _userController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final usuario = widget.authService.usuario!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bienvenido, ${usuario.nombreCompleto}')),
      );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPasswordRecovery() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperación de contraseña',
            style: TextStyle(color: _darkBrown, fontWeight: FontWeight.w700)),
        content: const Text('Funcionalidad pendiente de conexión con el servidor.',
            style: TextStyle(color: _warmGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _StudioBackdrop(),
            Container(color: const Color(0xB8FFF8F1)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 760;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: compact ? 16 : 28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          children: [
                            _buildLoginCard(compact),
                            SizedBox(height: compact ? 18 : 28),
                            const Text(
                              '© Lumibell Studios. Todos los derechos reservados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: _warmGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildLoginCard(bool compact) => Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: _darkBrown.withValues(alpha: .13),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              _BrandHeader(compact: compact),
              Padding(
                padding: EdgeInsets.fromLTRB(28, compact ? 24 : 30, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _welcomeHeading(),
                      SizedBox(height: compact ? 22 : 28),
                      if (_error != null) _errorMessage(),
                      _label('Usuario'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _userController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: _inputDecoration(
                            hint: 'Ingresa tu usuario',
                            icon: Icons.person_outline_rounded),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Ingresa tu usuario'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _label('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _inputDecoration(
                          hint: 'Ingresa tu contraseña',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: Semantics(
                            label: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            button: true,
                            child: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              color: _warmGrey,
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return value.length < 4
                              ? 'Ingresa una contraseña válida'
                              : null;
                        },
                      ),
                      SizedBox(height: compact ? 20 : 26),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _peach,
                            disabledBackgroundColor: _peach.withValues(alpha: .55),
                            foregroundColor: _darkBrown,
                            disabledForegroundColor:
                                _darkBrown.withValues(alpha: .5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: _brown))
                              : const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text('Ingresar',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.arrow_forward_rounded)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _showPasswordRecovery,
                        icon: const Icon(Icons.lock_reset_outlined, size: 20),
                        label: const Text('¿Olvidaste tu contraseña?'),
                        style: TextButton.styleFrom(
                          foregroundColor: _coral,
                          minimumSize: const Size.fromHeight(44),
                          textStyle: const TextStyle(fontSize: 15),
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 18),
                      _attendanceFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _welcomeHeading() => const Row(children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: _lightPeach,
            child: Icon(Icons.person_outline_rounded, size: 31, color: _brown)),
        SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bienvenido',
              style: TextStyle(
                  color: _darkBrown,
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  height: 1.05)),
          SizedBox(height: 5),
          Text('Inicia sesión para continuar',
              style: TextStyle(color: _warmGrey, fontSize: 16)),
        ])),
      ]);

  Widget _errorMessage() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2C7C0)),
        ),
        child: Text(_error!, style: const TextStyle(color: _coral)),
      );

  Widget _label(String label) => Text(label,
      style: const TextStyle(
          color: _darkBrown, fontSize: 16, fontWeight: FontWeight.w600));

  Widget _attendanceFooter() => const Column(children: [
        Row(children: [
          Expanded(child: Divider(color: _border)),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('Asistencia Lumibell',
                  style: TextStyle(color: _warmGrey, fontSize: 15))),
          Expanded(child: Divider(color: _border)),
        ]),
        SizedBox(height: 15),
        CircleAvatar(
            radius: 21,
            backgroundColor: _cream,
            child: Icon(Icons.groups_2_outlined, color: Color(0xFFFFA65F))),
        SizedBox(height: 12),
        Text('Tu asistencia, nuestro compromiso',
            textAlign: TextAlign.center,
            style: TextStyle(color: _darkBrown, fontSize: 15)),
      ]);

  InputDecoration _inputDecoration({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAA9B93)),
        prefixIcon: Icon(icon, color: const Color(0xFF97857B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _outline(_border),
        focusedBorder: _outline(_brown, width: 1.4),
        errorBorder: _outline(_coral),
        focusedErrorBorder: _outline(_coral, width: 1.4),
      );

  OutlineInputBorder _outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width));
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: compact ? 152 : 176,
        color: const Color(0xFFF4D9C0),
        alignment: Alignment.center,
        child: LumibellLogo(height: compact ? 104 : 118),
      );
}

class _StudioBackdrop extends StatelessWidget {
  const _StudioBackdrop();
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE7D9CB), Color(0xFFCAB19E)])),
        child: Stack(children: [
          Positioned(
              left: -60,
              bottom: 110,
              child: Icon(Icons.videocam_rounded,
                  size: 250, color: const Color(0xFF4A3C34).withValues(alpha: .18))),
          Positioned(
              right: -35,
              bottom: 76,
              child: Icon(Icons.local_florist_outlined,
                  size: 180, color: const Color(0xFF8C715B).withValues(alpha: .2))),
        ]),
      );
}
