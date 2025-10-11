import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultadoPesquisaPage extends StatefulWidget {
  final Map<String, String> filtros;

  const ResultadoPesquisaPage({Key? key, required this.filtros})
      : super(key: key);

  @override
  _ResultadoPesquisaPageState createState() => _ResultadoPesquisaPageState();
}

class _ResultadoPesquisaPageState extends State<ResultadoPesquisaPage> {
  List<DocumentSnapshot> clientes = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  Future<void> _pesquisar() async {
    setState(() {
      carregando = true;
    });

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('clientes').get();

    List<DocumentSnapshot> resultados = querySnapshot.docs;

    final filtros = widget.filtros;

    if (filtros['cpf'] != null && filtros['cpf']!.isNotEmpty) {
      String cpfFiltro = filtros['cpf']!.toLowerCase();
      resultados = resultados.where((doc) {
        final cpf = (doc['cpf'] ?? '').toString().toLowerCase();
        return cpf.contains(cpfFiltro);
      }).toList();
    }

    if (filtros['nome'] != null && filtros['nome']!.isNotEmpty) {
      String nomeFiltro = filtros['nome']!.toLowerCase();
      resultados = resultados.where((doc) {
        final nome = (doc['nome'] ?? '').toString().toLowerCase();
        return nome.contains(nomeFiltro);
      }).toList();
    }

    if (filtros['email'] != null && filtros['email']!.isNotEmpty) {
      String emailFiltro = filtros['email']!.toLowerCase();
      resultados = resultados.where((doc) {
        final email = (doc['email'] ?? '').toString().toLowerCase();
        return email.contains(emailFiltro);
      }).toList();
    }

    if (filtros['telefone'] != null && filtros['telefone']!.isNotEmpty) {
      String telefoneFiltro = filtros['telefone']!.toLowerCase();
      resultados = resultados.where((doc) {
        final telefone = (doc['telefone'] ?? '').toString().toLowerCase();
        return telefone.contains(telefoneFiltro);
      }).toList();
    }

    if (filtros['aniversario'] != null && filtros['aniversario']!.isNotEmpty) {
      String aniversarioFiltro = filtros['aniversario']!.toLowerCase();
      resultados = resultados.where((doc) {
        final aniversario = (doc['aniversario'] ?? '').toString().toLowerCase();
        return aniversario.contains(aniversarioFiltro);
      }).toList();
    }

    if (filtros['produto'] != null && filtros['produto']!.isNotEmpty) {
      String produtoFiltro = filtros['produto']!.toLowerCase();
      resultados = resultados.where((doc) {
        final produto = (doc['produto'] ?? '').toString().toLowerCase();
        return produto.contains(produtoFiltro);
      }).toList();
    }

    if (filtros['marca'] != null && filtros['marca']!.isNotEmpty) {
      String marcaFiltro = filtros['marca']!.toLowerCase();
      resultados = resultados.where((doc) {
        final marca = (doc['marca'] ?? '').toString().toLowerCase();
        return marca.contains(marcaFiltro);
      }).toList();
    }

    if (filtros['observacoes'] != null && filtros['observacoes']!.isNotEmpty) {
      String obsFiltro = filtros['observacoes']!.toLowerCase();
      resultados = resultados.where((doc) {
        final obs = (doc['observacoes'] ?? '').toString().toLowerCase();
        return obs.contains(obsFiltro);
      }).toList();
    }

    if (filtros['dataCadastro'] != null &&
        filtros['dataCadastro']!.isNotEmpty) {
      try {
        final formato = DateFormat('dd/MM/yyyy');
        final dataFiltro = formato.parse(filtros['dataCadastro']!);

        resultados = resultados.where((doc) {
          if (doc['dataCadastro'] != null &&
              doc['dataCadastro'] is Timestamp) {
            final data = (doc['dataCadastro'] as Timestamp).toDate();
            return data.day == dataFiltro.day &&
                data.month == dataFiltro.month &&
                data.year == dataFiltro.year;
          }
          return false;
        }).toList();
      } catch (e) {
        debugPrint('Erro ao converter data: $e');
      }
    }

    // 🔠 Ordena os clientes alfabeticamente por nome (A–Z)
resultados.sort((a, b) {
  final nomeA = ((a.data() as Map<String, dynamic>)['nome'] ?? '').toString().toLowerCase();
  final nomeB = ((b.data() as Map<String, dynamic>)['nome'] ?? '').toString().toLowerCase();
  return nomeA.compareTo(nomeB);
});

setState(() {
  clientes = resultados;
  carregando = false;
});

  }

  String _formatarCampo(String? valor) {
    return (valor == null || valor.isEmpty) ? '-' : valor;
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final data = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(data);
  }

  Future<void> _abrirWhatsApp(String numero) async {
    final telefoneLimpo = numero
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^0+'), '');

    final url = Uri.parse("https://wa.me/55$telefoneLimpo?text=Olá,%20tudo%20bem?");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Pesquisa'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
              ? const Center(child: Text('Nenhum cliente encontrado.'))
              : ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    var cliente = clientes[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(_formatarCampo(cliente['nome'])),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CPF: ${_formatarCampo(cliente['cpf'])}'),
                            Text('Email: ${_formatarCampo(cliente['email'])}'),
                            Text('Telefone: ${_formatarCampo(cliente['telefone'])}'),
                            Text('Aniversário: ${_formatarCampo(cliente['aniversario'])}'),
                            Text('Produto: ${_formatarCampo(cliente['produto'])}'),
                            Text('Marca: ${_formatarCampo(cliente['marca'])}'),
                            Text('Observações: ${_formatarCampo(cliente['observacoes'])}'),
                            Text('Data de Cadastro: ${_formatarData(cliente['dataCadastro'])}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          onPressed: () {
                            final telefone = cliente['telefone'] ?? '';
                            if (telefone.isNotEmpty) {
                              _abrirWhatsApp(telefone);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
