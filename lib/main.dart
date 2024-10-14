import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'models/todo.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Posts App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(title: 'Posts App'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier{
  var favorites = <Todo>[];

  void toggleFavorite(Todo todo) {
    if (favorites.map((todo) => todo.id).toList().contains(todo.id)) {
      favorites.remove(todo);
    } else {
      favorites.add(todo);
    }
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    GetPage(),
    PostPage(),
    FavoritePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: Builder(
          builder: (context) {
            return IconButton(
            onPressed: (){
              Scaffold.of(context).openDrawer();
                },
            icon: const Icon(Icons.menu),
            );
          },
        ),
      ),
      body: Center(
        child: _widgetOptions[selectedIndex],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: Icon(Icons.view_list),
              title: const Text('Posts'),
              selected: selectedIndex == 0,
              onTap: () {
                  _onItemTapped(0);
                  Navigator.pop(context);
              }
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: const Text('Write Post'),
              selected: selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              }
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: const Text('Favorites'),
              selected: selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              }
            )
          ],
        ),
      )
    );
  }
}

class GetPage extends StatefulWidget{
  @override
  State<GetPage> createState() => _GetPageState();
}

class _GetPageState extends State<GetPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: _fetchTodos(),
          builder: (context, AsyncSnapshot<List<Todo>> snapshot) {
            if (snapshot.hasData) {
              return ListView.separated(
                itemBuilder: (context, index) {
                  final todo = snapshot.data![index];
                  return ListTile(
                    title: Text(todo.title),
                    subtitle: Text(todo.description),
                    leading: Text(todo.id),
                    trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            appState.toggleFavorite(todo);
                          });
                        },
                        icon: Icon(
                          appState.favorites.map((todo) => todo.id).toList().contains(todo.id) ? Icons.favorite : Icons.favorite_border, color: Colors.red
                        )
                    ),
                    onTap: () =>
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(
                          '${todo.title} has been pressed!'))
                      )
                    },
                  );
                },
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                itemCount: snapshot.data!.length
              );
            } else {
              return Text('No data found');
            }
          }
      ),
      ),
    );
  }


  Future<List<Todo>> _fetchTodos() async{
    final uri = Uri.parse('https://6702bc3abd7c8c1ccd3fb4f8.mockapi.io/api/v1/todos/');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      List<Todo> todos = jsonResponse.map((json) => Todo.fromJson(json)).toList();
      return todos;
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}

class PostPage extends StatefulWidget{
  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  String result = '';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Decoration'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
                onPressed: _postTodos,
                child: Text('Submit')
            ),
            SizedBox(height: 20.0),
            Text(
              result,
              style: TextStyle(fontSize: 16.0),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _postTodos() async {
    var uuid = Uuid();
    final uri = Uri.parse('https://6702bc3abd7c8c1ccd3fb4f8.mockapi.io/api/v1/todos/');
    final Todo todo = new Todo(
        id: uuid.v4(),
        title: titleController.text,
        description: descriptionController.text,
        createdAt: DateTime.now()
    );
    final response = await http.post(
      uri,
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      setState(() {
        result =
        'ID: ${responseData['id']}\nTitle: ${responseData['title']}\nDescription: ${responseData['description']}';
      });
    } else {
      throw Exception('Failed to post data');
    }
  }
}

class FavoritePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if(appState.favorites.isEmpty){
      return Center(
        child: Text('No favorites yet. '),
      );
    }

    return ListView.separated(
      itemBuilder: (context, index) {
        final todo = appState.favorites[index];
        return ListTile(
          title: Text(todo.title),
          subtitle: Text(todo.description),
          leading: Text(todo.id),
          onTap: () =>
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(
                '${todo.title} has been pressed!'))
            )
          },
        );
      },
      separatorBuilder: (context, index) {
        return const Divider();
      },
      itemCount: appState.favorites.length
    );
  }
}
