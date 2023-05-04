import 'form_framework.dart';
import 'models.dart';

class Pessoa {
  Texto nome = Texto('Nome', 'Digite seu nome', 1);
  Texto sobrenome = Texto('Sobrenome', 'Digite seu sobrenome', 2);
  Data nascimento = Data('Nascimento', DateTime.now(), 'Data de nascimento', 3);
  Data morte = Data('Morte', DateTime.now(), 'Data de falecimento', 4);
  Frase historia = Frase('Historia', 'Digite sua história', 5);
}

void main() {
  Pessoa campos = Pessoa();
  gerarForm(campos);
  gerarTabela(campos);
  iniciarServidor();
}
