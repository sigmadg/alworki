/// Rutas de imágenes (misma lógica que `getImageUrl` en Vue).
class AssetPaths {
  AssetPaths._();

  static const _root = 'assets/images';

  static String resolve(String key) {
    if (key.isEmpty) return '$_root/users/user.jpg';
    if (key.startsWith('assets/')) return key;
    if (key.startsWith('users/')) return '$_root/$key';
    if (key.startsWith('categories/')) return '$_root/$key';
    if (key.startsWith('background/')) return '$_root/$key';
    if (key.startsWith('background') && key.endsWith('.png')) {
      return '$_root/background/$key';
    }
    // Claves legacy de la primera migración
    return switch (key) {
      'english' => '$_root/background/background1.png',
      'pets' => '$_root/background/background2.png',
      'music' => '$_root/background/background3.png',
      'home' => '$_root/background/background4.png',
      'food' => '$_root/background/background5.png',
      'u1' => '$_root/users/1.jpg',
      'u2' => '$_root/users/2.jpg',
      'u3' => '$_root/users/3.jpg',
      'u4' => '$_root/users/4.jpg',
      'u5' => '$_root/users/5.jpg',
      'me' => '$_root/users/user.jpg',
      _ => '$_root/users/user.jpg',
    };
  }

  static String profileHeader = '$_root/background/img-profile-bg.png';
}
