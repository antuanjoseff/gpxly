class UserProfile {
  final String sexo;
  final int altura;
  final int peso;

  UserProfile({required this.sexo, required this.altura, required this.peso});

  UserProfile copyWith({String? sexo, int? altura, int? peso}) {
    return UserProfile(
      sexo: sexo ?? this.sexo,
      altura: altura ?? this.altura,
      peso: peso ?? this.peso,
    );
  }
}
