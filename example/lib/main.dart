import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seq_logger/seq_logger.dart';

void main() {
  if (!SeqLogger.initialized) {
    SeqLogger.init(
      url: 'your_seq_url_here',
      apiKey: "YOUR_APIKEY_HERE",
      batchSize: 50,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController messageController;
  late TextEditingController dataController;
  LogLevel selectedLogLevel = LogLevel.debug;
  String logUsageText = "";
  bool dataError = false;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    dataController = TextEditingController();
  }

  @override
  void dispose() {
    messageController.dispose();
    dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => SeqLogger.sendLogs(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: messageController,
              maxLines: 1,
              onChanged: (value) => populateSampleData(),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Your Message Template",
                  hintText: "my foo value is {foo} and {mySample}"),
            ),
            DropdownButton<LogLevel>(
              value: selectedLogLevel,
              items: const [
                DropdownMenuItem<LogLevel>(
                    value: LogLevel.info, child: Text("info")),
                DropdownMenuItem<LogLevel>(
                    value: LogLevel.warning, child: Text("warning")),
                DropdownMenuItem<LogLevel>(
                    value: LogLevel.debug, child: Text("debug")),
                DropdownMenuItem<LogLevel>(
                    value: LogLevel.error, child: Text("error")),
                DropdownMenuItem<LogLevel>(
                    value: LogLevel.verbose, child: Text("verbose")),
              ],
              onChanged: (LogLevel? v) {
                if (v != null) {
                  setState(() => selectedLogLevel = v);
                }
                populateSampleData();
              },
            ),
            TextField(
              controller: dataController,
              minLines: 5,
              maxLines: 10,
              onChanged: (value) => populateSampleData(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Log Map Data",
                hintText: '''
{
  "foo": "bar",
  "mySample": true,
}
                ''',
              ),
            ),
            const Divider(),
            const Text("Usage"),
            Text(dataError
                ? "Cannot parse 'Log Map Data' as Map"
                : logUsageText),
            ElevatedButton(
                onPressed: logUsageText.isEmpty
                    ? null
                    : () {
                        SeqLogger.addLogToDb(
                            message: messageController.text,
                            level: selectedLogLevel,
                            data: dataController.text.isEmpty
                                ? null
                                : json.decode(dataController.text));
                      },
                child: const Text("Add Log")),
            const Divider(),
            ElevatedButton(
                onPressed: () {
                  SeqLogger.addLogToDb(
                    message: "APP my foo is {foo}, my boolean is {b}",
                    data: {
                      "foo": "bar",
                      "b": true,
                      "additional": [
                        {"complexObject": 1},
                        {"complexObject": 2, "hello": "world"},
                      ]
                    },
                    level: LogLevel.info,
                  );
                },
                child: const Text("Add a Random Log"))
          ],
        ),
      ),
    );
  }

  void populateSampleData() {
    if (messageController.text.isNotEmpty) {
      if (dataController.text.isEmpty) {
        setState(() => dataError = false);
        setState(() {
          logUsageText = '''
SeqLogger.addLogToDb(
  message: "${messageController.text}",
  level: $selectedLogLevel,
);
              ''';
        });
      } else {
        try {
          Map<String, dynamic> dataMap = json.decode(dataController.text);

          setState(() => dataError = false);
          setState(() {
            logUsageText = '''
SeqLogger.addLogToDb(
  message: "${messageController.text}",
  level: $selectedLogLevel,
  data: ${json.encode(dataMap)}
);
              ''';
          });
        } catch (ex) {
          setState(() => dataError = true);
        }
      }
    } else {
      setState(() {
        logUsageText = '';
      });
    }
  }
}
