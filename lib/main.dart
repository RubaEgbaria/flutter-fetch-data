import 'dart:async';
import 'dart:convert';
// import 'dart:html';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MyAppState())],
      child: const MyApp(),
    ));

Future<List<Data>> fetchData() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/photos'));

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body) as List<dynamic>;
    return jsonData.map((item) => Data.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load');
  }
}

class Data {
  final int id;
  final String title;
  final String url;

  const Data({
    required this.id,
    required this.title,
    required this.url,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'],
      title: json['title'],
      url: json['url'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Data'),
        ),
        body: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const GridBuilder();
        break;
      case 1:
        page = const FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use a more mobile-friendly layout with BottomNavigationBar
          // on narrow screens.
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Feed',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list),
                      label: 'Selected',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class GridBuilder extends StatefulWidget {
  const GridBuilder({
    Key? key,
  }) : super(key: key);

  @override
  GridBuilderState createState() => GridBuilderState();
}

class GridBuilderState extends State<GridBuilder> {
  late Future<List<Data>> futureData;
  List<Color> itemColors = [];

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Data>>(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final dataList = snapshot.data!;
          if (itemColors.isEmpty) {
            itemColors =
                List<Color>.filled(dataList.length, Colors.transparent);
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              crossAxisSpacing: 3,
              mainAxisSpacing: 5,
              maxCrossAxisExtent: 290,
              childAspectRatio: 400 / 280,
            ),
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              final data = dataList[index];
              final isFavorite = Provider.of<MyAppState>(context, listen: false)
                  .isFavorite(data);
              final color = isFavorite ? Colors.green : Colors.transparent;
              return Center(
                child: GestureDetector(
                  onTap: () {
                    Provider.of<MyAppState>(context, listen: false)
                        .toggleFavorite(data.title);
                    setState(() {
                      itemColors[index] =
                          isFavorite ? Colors.transparent : Colors.green;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: color,
                    child: Center(
                      child: Text(
                        data.title,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    var list = Provider.of<MyAppState>(context).jsonList;

    if (list.isEmpty) {
      return const Center(
        child: Text('No items selected yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(40),
          child: Text("Selected items"),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // design
              maxCrossAxisExtent: 500,
              childAspectRatio: 400 / 80,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final data = list[index];
              return ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.add),
                  color: theme.colorScheme.primary,
                  onPressed: () {},
                ),
                title: Text(
                  data,
                  style: const TextStyle(fontSize: 20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MyAppState extends ChangeNotifier {
  late List<String> jsonList = [];

  void toggleFavorite(String data) {
    if (jsonList.contains(data)) {
      jsonList.remove(data);
    } else {
      jsonList.add(data);
    }
    notifyListeners();
  }

  bool isFavorite(Data data) {
    return jsonList.contains(data.title);
  }
}
