import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/todo_model.dart';
import '../../services/data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List toDoList = [];

  final _controller = TextEditingController();

  final _service = DataService();

  @override
  void initState() {
    super.initState();

    _service.readData().then((data) {
      setState(() {
        log('JSON: $data');
        if (data != null) {
          toDoList = jsonDecode(data);
        }
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('ToDo List')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                maxLines: 2,
                // Adição do controlador de texto
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'To Do',
                  filled: true,
                  prefixIcon: Icon(
                    Icons.text_fields_rounded,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: toDoList.length,
                itemBuilder: (context, position) {
                  var todo;
                  return Dismissible(
                    key: Key("$position"),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        // 8. Remoção do item na lista de referencia
                        toDoList.removeAt(position);

                        // 9. Chamada de serviço para persistir a remoção
                        _service.saveData(toDoList);
                      });
                    },
                    child: CheckboxListTile(
                      secondary: CircleAvatar(
                        child: todo.concluido
                            ? const Icon(Icons.check)
                            : const Icon(Icons.warning),
                      ),
                      value: todo.concluido,
                      title: Text(
                        todo.conteudo,
                        style: TextStyle(
                            decoration: todo.concluido
                                ? TextDecoration.lineThrough
                                : TextDecoration.none),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Criada em ${todo.dataCriacao}'),
                          Text(
                            todo.dataConclusao.isEmpty
                                ? ''
                                : 'Finalizada em ${todo.dataConclusao}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      onChanged: (inChecked) {
                        // 13. Mudança de estado da tarefa
                        setState(() {
                          // Atualização de sintaxe de map JSON para objetos
                          todo.concluido = inChecked!;
                          if (inChecked) {
                            // 14. Formatação de data com intl.
                            todo.dataConclusao = DateFormat('d/M/y HH:mm:ss')
                                .format(DateTime.now());
                          } else {
                            todo.dataConclusao = '';
                          }

                          // 15. Persistencia da alteração de estado da tarefa.
                          toDoList[position] = todo.toJson();
                          _service.saveData(toDoList);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ));
    // ignore: dead_code
    FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            final conteudo = _controller.text;

            // Verifica se o Widget já foi criado pelo anteriormente
            if (!mounted) return;

            if (conteudo.isEmpty) {
              // Exibição de mensagem de validação de conteúdo obrigatório para preenchimento
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Preencha a tarefa.'),
                ));
              return;
            }

            var newTodo = Todo(conteudo: conteudo);

            // Atualização para conversao de objeto em mapa para persistencia em JSON
            toDoList.add(newTodo.toJson());
            _controller.text = '';

            _service.saveData(toDoList);
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'));
  }
}
