class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.name,
    required this.role,
  });

  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String name;
  final String role;

  bool get isGuest => role == 'guest';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'name': name,
        'role': role,
      };

  static const AppUser guest = AppUser(
    id: 0,
    email: '',
    firstname: 'Invitado',
    lastname: '',
    name: 'Invitado',
    role: 'guest',
  );
}
