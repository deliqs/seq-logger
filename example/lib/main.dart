import 'dart:math';

import 'package:flutter/material.dart';
import 'package:seq_logger/seq_logger.dart';

void main() {
  if (!SeqLogger.initialized) {
    SeqLogger.init(url: "YOUR_API_ENDPOINT_URL_HERE");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyPage(),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int recordCount = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("SeqLogger Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green.shade300),
                ),
                onPressed: (() async {
                  int recCount = await SeqLogger.getRecordCount();
                  setState(() {
                    recordCount = recCount;
                  });
                }),
                child: Text(
                  "Click:  $recordCount",
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blueAccent.shade200),
                ),
                onPressed: () {
                  String sampleLog = sampleLogs.first;
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: TextField(
                                    autofocus: true,
                                    controller: TextEditingController(text: Utils.generateRandom()),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter ',
                                    )),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      var r = sampleLog;
                                      SeqLogger.logInfo(message: r);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Save"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Back"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    isScrollControlled: true,
                  );
                },
                child: const Text(
                  "Add Sample",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.purple.shade300),
                ),
                onPressed: () {
                  SeqLogger.sendLogs();
                },
                child: const Text(
                  "Send",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

const List<String> sampleLogs = [
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "Sed ultricies metus ut ultrices commodo.",
  "Etiam ut nisi ac urna tempor vehicula",
  "Cras vitae magna eleifend, imperdiet ex eget, rutrum dolor.",
  "Aliquam porttitor dolor sed efficitur porttitor.",
  "Donec a justo id felis hendrerit scelerisque.",
  "Pellentesque id nunc dignissim, volutpat lectus eget, vestibulum metus.",
  "Curabitur sed lorem ut erat vestibulum posuere consequat vitae metus.",
  "Quisque lobortis leo ut tristique faucibus.",
  "Nam eget mi non nibh sagittis ultricies.",
  "Vestibulum sed neque ac sem dictum ullamcorper.",
  "Maecenas vitae nulla volutpat diam dignissim rhoncus.",
  "Nulla fermentum lectus vel iaculis posuere.",
  "Cras eget erat at erat suscipit porttitor id ut libero.",
];

class Utils {
  static String generateRandom() {
    final random = Random();
    const availableChars = sampleLogs;
    final randomString = List.generate(1, (index) => availableChars[random.nextInt(availableChars.length)]).join();

    return randomString;
  }
}
