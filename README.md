# seq_logger

Seq compatible logger package for Flutter.\
more info for seq: https://datalust.co/seq


With Flutter:

```
 $ flutter pub add seq_logger
```
 
This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):

```
dependencies:
  seq_logger: ^1.0.3
```

Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

Import it
Now in your Dart code, you can use:
```
import 'package:seq_logger/seq_logger.dart';
```

## How to Use 
Init Package in your main function.
```
void main() {
  if (!SeqLogger.initialized) {
    SeqLogger.init(url: "YOUR_API_ENDPOINT_URL_HERE", apiKey: "YOUR_API_KEY");
  }

  runApp(const MyApp());
}
```
 
 
Add your logs whenever required.
You can use template in your message string and provide values in data field.
Your logs will be collected on device.
 ```
 SeqLogger.addLogToDb(
    message: "Your log message here with {Awesome} template",
    level: LogLevel.debug,
    data: {
      "Awesome": "the value that will highlighted in your template",
      "yourKey": "Your value",
      "yourOtherKey": false,
    },
  );
 ```
 
 Trigger sending collected logs.
 Process will send collected logs based on your batchsize parameter.
 ```
 SeqLogger.sendLogs();
 ```
 
Gives the number of logs stored in the database. 
 
 ```
 int count = await SeqLogger.getRecordCount();
 
 ```
 
 
