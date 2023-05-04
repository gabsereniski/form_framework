export 'models.dart';

class Texto {
  String nome;
  String verboso;
  int id;

  Texto(this.nome, this.verboso, this.id);
}

class Frase {
  String nome;
  String verboso;
  int id;

  Frase(this.nome, this.verboso, this.id);
}

class Data {
  String nome;
  DateTime data;
  String verboso;
  int id;

  Data(this.nome, this.data, this.verboso, this.id);
}

class Numero {
  int valor;
  String verboso;
  Numero({this.verboso = "", this.valor = 0});
}
