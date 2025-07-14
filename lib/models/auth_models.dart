class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}

class User {
  final String email;
  final String role;

  User({
    required this.email,
    required this.role,
  });

  factory User.fromToken(String token) {
    // Aquí decodificaríamos el JWT para extraer la información del usuario
    // Por ahora, retornamos un usuario básico
    return User(
      email: '',
      role: '',
    );
  }
}
