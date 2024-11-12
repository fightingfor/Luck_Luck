import 'package:flutter/material.dart';
import 'package:lucky_lucky/BallInfo.dart';
import 'package:lucky_lucky/DatabaseHelper.dart';
import 'package:lucky_lucky/loadData.dart';

void main() {
  runApp(const MyApp());
  checkDbAndInsert();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _content = "";
  final dbHelper = DatabaseHelper();

  void _incrementCounter() async {
    List<BallInfo> ballInfoList = await loadJsonData();
    List<BallInfo> databasesInfo = await dbHelper.getAllBalls();
    fetchAndInsertData();
    setState(() {
      _counter = ballInfoList.length;
      _content = "数据库查询数据 ${databasesInfo.length}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _content,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
