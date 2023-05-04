import 'dart:io';
import 'models.dart'; // importa o arquivo models.dart, que contém as classes Texto, Data e Frase
import 'dart:mirrors';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart'; // importa a biblioteca sqlite3

export 'form_framework.dart'; // exporta o arquivo reflexao.dart

// Função que gera um formulário HTML a partir de um objeto campos
String gerarForm(dynamic campos) {
  var instanceMirror = reflect(campos);
  var classMirror = instanceMirror.type;
  var className = MirrorSystem.getName(classMirror.simpleName);

  var html = '''
    <!DOCTYPE html>
    <html>
      <head>
        <title>$className</title>
      </head>
      <body>
        <center>
          <form method="POST">
            <H1>🌼🌸❀✿🌷 $className 🌷✿❀🌸🌼</H1>
            <input type="hidden" name="Tabela" value="$className" />
  ''';

  for (var fieldName in classMirror.declarations.keys) {
    var declaration = classMirror.declarations[fieldName];
    if (declaration is VariableMirror) {
      var fieldType = declaration.type.reflectedType;

      if (fieldType == Texto) {
        var texto =
            instanceMirror.getField(declaration.simpleName).reflectee as Texto;
        var label = _generateLabel(texto.nome, texto.verboso);
        var input = _generateInput(texto.nome, texto.id.toString(), 'text');
        html += '$label$input';
      } else if (fieldType == Data) {
        var data =
            instanceMirror.getField(declaration.simpleName).reflectee as Data;
        var label = _generateLabel(data.nome, data.verboso);
        var input = _generateInput(data.nome, data.id.toString(), 'date');
        html += '$label$input';
      } else if (fieldType == Frase) {
        var frase =
            instanceMirror.getField(declaration.simpleName).reflectee as Frase;
        var label = _generateLabel(frase.nome, frase.verboso);
        var textarea = _generateTextarea(frase.nome, frase.id.toString());
        html += '$label$textarea';
      }
    }
  }

  html += '''
            <button type="submit">Enviar</button>
          </form>
        </center>
      </body>
    </html>
  ''';

  File('formulario.html').writeAsStringSync(html);

  return html;
}

String _generateLabel(String name, String verbose) {
  return '''
            <label for="$name">$verbose:</label><br>
  ''';
}

String _generateInput(String name, String id, String type) {
  return '''
            <input type="$type" name="$name" id="$id" /><br><br>
  ''';
}

String _generateTextarea(String name, String id) {
  return '''
            <textarea name="$name" id="$id"></textarea><br><br>
  ''';
}

String gerarTabela(dynamic campos) {
  var file = File('dados.db');

  if (!file.existsSync()) {
    file.createSync();
  }

  var db = sqlite3.open('dados.db');

  InstanceMirror instanceMirror = reflect(campos);
  String className = MirrorSystem.getName(instanceMirror.type.simpleName);
  ClassMirror classMirror = instanceMirror.type;

  Set<String> camposAdicionados = {};

  String tabela = '';

  // Função auxiliar que modifica o nome do campo original caso já exista na tabela
  String criarNomeModificado(String nomeOriginal) {
    int contador =
        camposAdicionados.where((campo) => campo == nomeOriginal).length;
    camposAdicionados.add(nomeOriginal);
    return contador > 0 ? "$nomeOriginal$contador" : nomeOriginal;
  }

  for (var fieldName in classMirror.instanceMembers.keys) {
    var field = classMirror.declarations[fieldName];
    if (field is VariableMirror) {
      String name = MirrorSystem.getName(field.simpleName);
      var fieldType = field.type.reflectedType;

      String nomeModificado = criarNomeModificado(name);

      // Adiciona o tipo de dado na string da tabela de acordo com o tipo do campo
      if (fieldType == Texto) {
        instanceMirror.getField(field.simpleName).reflectee as Texto;
        tabela += '$nomeModificado TEXT,';
      } else if (fieldType == Data) {
        instanceMirror.getField(field.simpleName).reflectee as Data;
        tabela += '$nomeModificado DATE,';
      } else if (fieldType == Frase) {
        instanceMirror.getField(field.simpleName).reflectee as Frase;
        tabela += '$nomeModificado TEXT,';
      }
    }
  }

  if (tabela.isNotEmpty) {
    tabela = tabela.substring(0, tabela.length - 1);
  }

  db.execute('DROP TABLE IF EXISTS $className ');
  db.execute('CREATE TABLE IF NOT EXISTS $className ($tabela)');

  return tabela;
}

// ----------------------------- SERVIDOR ----------------------------- //

// Função que retorna uma resposta com o conteúdo do arquivo 'formulario.html'
Response _formulario(Request request) {
  return Response.ok(File('formulario.html').readAsStringSync(),
      headers: {'Content-Type': 'text/html'});
}

Future<Response> _processarFormulario(Request request) async {
  // Lê o corpo da requisição (o formulário submetido)
  final bodyBytes = await request.read().toList();

  // Decodifica o corpo da requisição (que está em bytes) para uma string UTF-8
  final body = utf8.decode(bodyBytes.expand((x) => x).toList());

  // Converte a string contendo o formulário em um mapa de dados
  final formData = Uri.splitQueryString(body);

  // Abre uma conexão com o banco de dados SQLite3
  final conn = sqlite3.open('dados.db');

  // Prepara a string com os nomes dos campos e valores a serem inseridos
  String campos = '';
  String valores = '';
  for (var campo in formData.keys.skip(1)) {
    campos += '$campo,';
    valores += '?,';
  }

  campos = campos.substring(0, campos.length - 1);
  valores = valores.substring(0, valores.length - 1);

  // Cria uma lista com os valores a serem inseridos na tabela
  List<dynamic> valoresInsercao = [];
  for (var valor in formData.values.skip(1)) {
    valoresInsercao.add(valor);
  }

  var tableName = formData.values.first;

  // Insere os dados do formulário na tabela 'formulario'
  conn.execute(
      'INSERT INTO $tableName ($campos) VALUES ($valores)', valoresInsercao);

  // Fecha a conexão com o banco de dados
  conn.dispose();

  // Retorna uma resposta de sucesso indicando que os dados foram salvos
  return Response.ok('Dados salvos com sucesso!',
      headers: {'Content-Type': 'text/plain'});
}

// Função principal que configura o roteamento e inicia o servidor
Future<void> iniciarServidor() async {
  // Cria uma instância do roteador do Shelf
  final _app = Router();
  _app.get('/form', _formulario);
  _app.post('/form', _processarFormulario);

  // Inicia o servidor na porta 2345
  var server = await shelf_io.serve(_app, InternetAddress.anyIPv4, 2345);
  print('Servidor rodando em ${server.address}:${server.port}/form');
}
