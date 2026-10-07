class AuthValidators {
  AuthValidators._();

  static final _strongPassword = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]).+$',
  );

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El correo es requerido';
    if (!t.contains('@') || !t.contains('.')) return 'Correo electrónico no válido';
    return null;
  }

  static String? phone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El número es requerido';
    final digits = t.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Número de WhatsApp no válido';
    return null;
  }

  static String? loginIdentity(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Correo o teléfono requerido';
    if (t.contains('@')) return email(t);
    return phone(t);
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es requerida';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!_strongPassword.hasMatch(v)) {
      return 'La contraseña debe de contener, por lo menos una letra mayúscula, números y caracteres especiales.';
    }
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != password) return 'La contraseña debe coincidir';
    return null;
  }
}
