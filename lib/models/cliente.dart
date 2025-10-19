class Cliente {
  final String id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? nascimento;
  final String? produto;
  final List<String> marcas;
  final String? observacoes;

  Cliente({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.nascimento,
    this.produto,
    required this.marcas,
    this.observacoes,
  });

  factory Cliente.fromMap(String id, Map<String, dynamic> data) {
    return Cliente(
      id: id,
      nome: (data['nome'] ?? '').toString(),
      email: data['email'] as String?,
      telefone: data['telefone'] as String?,
      nascimento: data['nascimento'] as String?,
      produto: data['produto'] as String?,
      marcas: (data['marcas'] as List?)?.whereType<String>().toList() ?? [],
      observacoes: data['observacoes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'nascimento': nascimento,
      'produto': produto,
      'marcas': marcas,
      'observacoes': observacoes,
    }..removeWhere((k, v) => v == null);
  }
}
