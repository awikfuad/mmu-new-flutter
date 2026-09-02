import '../common/enums.dart';

class AuthUser {
  final int id;
  final String name;
  final String? username;
  final String? nim;
  final String? phone;
  final Role role;
  final Lembaga lembaga;
  final String? tanggalLahir;
  final String? foto;

  const AuthUser({
    required this.id,
    required this.name,
    this.username,
    this.nim,
    this.phone,
    required this.role,
    required this.lembaga,
    this.tanggalLahir,
    this.foto,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        name: (j['name'] ?? '').toString(),
        username: j['username']?.toString(),
        nim: j['nim']?.toString(),
        phone: j['phone']?.toString(),
        role: RoleX.from(j['role']?.toString()),
        lembaga: LembagaX.from(j['lembaga']?.toString()),
        tanggalLahir: j['tanggal_lahir']?.toString() ?? j['tanggalLahir']?.toString(),
        foto: j['foto']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (username != null) 'username': username,
        if (nim != null) 'nim': nim,
        if (phone != null) 'phone': phone,
        'role': role.apiValue,
        'lembaga': lembaga.apiValue,
        if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
        if (foto != null) 'foto': foto,
      };

  bool get isAdmin => role == Role.admin;
  bool get isTeacher => role == Role.teacher;
  bool get isStudent => role == Role.user;
  bool get isParent => role == Role.parent;

  AuthUser copyWith({
    int? id,
    String? name,
    String? username,
    String? nim,
    String? phone,
    Role? role,
    Lembaga? lembaga,
    String? tanggalLahir,
    String? foto,
  }) =>
      AuthUser(
        id: id ?? this.id,
        name: name ?? this.name,
        username: username ?? this.username,
        nim: nim ?? this.nim,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        lembaga: lembaga ?? this.lembaga,
        tanggalLahir: tanggalLahir ?? this.tanggalLahir,
        foto: foto ?? this.foto,
      );
}
