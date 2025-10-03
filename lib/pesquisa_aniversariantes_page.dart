import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

class PesquisaAniversariantesPage extends StatefulWidget {
  const PesquisaAniversariantesPage({super.key});

  @override
  _PesquisaAniversariantesPageState createState() =>
      _PesquisaAniversariantesPageState();
}

class _PesquisaAniversariantesPageState
    extends State<PesquisaAniversariantesPage> {
  String? mesSelecionado;
  List<DocumentSnapshot> resultados = [];

  final List<String> meses = const [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];

  @override
  void initState() {
    super.initState();
    // Garante formatação local para datas (evita LocaleDataException)
    Intl.defaultLocale = 'pt_BR';
    initializeDateFormatting('pt_BR');
  }

  Future<void> pesquisarAniversariantes() async {
    if (mesSelecionado == null) return;

    final mesNumero = meses.indexOf(mesSelecionado!) + 1;
    final querySnapshot =
        await FirebaseFirestore.instance.collection('clientes').get();

    final List<DocumentSnapshot> aniversariantes = [];
    for (var doc in querySnapshot.docs) {
      final valor = doc['aniversario'];
      if (valor != null && valor.toString().trim().isNotEmpty) {
        try {
          final data =
              DateFormat("dd/MM/yyyy").parse(valor.toString().trim());
          if (data.month == mesNumero) {
            aniversariantes.add(doc);
          }
        } catch (_) {
          // Ignora registros com data inválida
        }
      }
    }

    setState(() {
      resultados = aniversariantes;
    });
  }

  /// MESMA lógica robusta para ambas as telas:
  /// tenta whatsapp://, depois api.whatsapp.com, depois wa.me (sem canLaunch).
  Future<void> _abrirWhatsApp(String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefone inválido ou vazio.")),
      );
      return;
    }
    final numeroFinal =
        numeroLimpo.startsWith('55') ? numeroLimpo : '55$numeroLimpo';

    final texto = "Olá Parabéns pelo seu aniversário!";
    final encoded = Uri.encodeComponent(texto);

    final uriScheme =
        Uri.parse('whatsapp://send?phone=$numeroFinal&text=$encoded');
    final uriApi =
        Uri.parse('https://api.whatsapp.com/send?phone=$numeroFinal&text=$encoded');
    final uriWame = Uri.parse('https://wa.me/$numeroFinal?text=$encoded');

    bool abriu = false;

    // 1) Tenta esquema nativo
    try {
      abriu = await launchUrl(uriScheme, mode: LaunchMode.externalApplication);
    } catch (_) {
      abriu = false;
    }

    // 2) Tenta API web do WhatsApp
    if (!abriu) {
      try {
        abriu = await launchUrl(uriApi, mode: LaunchMode.externalApplication);
      } catch (_) {
        abriu = false;
      }
    }

    // 3) Tenta wa.me
    if (!abriu) {
      try {
        abriu = await launchUrl(uriWame, mode: LaunchMode.externalApplication);
      } catch (_) {
        abriu = false;
      }
    }

    if (!abriu) {
      // Mensagem clara para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o WhatsApp")),
      );
    }
  }

  String _formatarCampo(String? valor) {
    return (valor == null || valor.trim().isEmpty) ? '-' : valor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesquisa de Aniversariantes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: mesSelecionado,
              decoration: const InputDecoration(
                labelText: "Selecione o mês",
                border: OutlineInputBorder(),
              ),
              items: meses
                  .map((mes) => DropdownMenuItem(value: mes, child: Text(mes)))
                  .toList(),
              onChanged: (value) => setState(() => mesSelecionado = value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pesquisarAniversariantes,
              child: const Text("Pesquisar"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: resultados.isEmpty
                  ? const Center(
                      child: Text("Nenhum aniversariante encontrado"),
                    )
                  : ListView.builder(
                      itemCount: resultados.length,
                      itemBuilder: (context, index) {
                        final cliente =
                            resultados[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          child: ListTile(
                            title: Text(_formatarCampo(cliente['nome'])),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Aniversário: ${_formatarCampo(cliente['aniversario'])}'),
                                Text(
                                    'Telefone: ${_formatarCampo(cliente['telefone'])}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () {
                                final telefone = (cliente['telefone'] ?? '').toString();
                                if (telefone.isNotEmpty) {
                                  _abrirWhatsApp(telefone);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
