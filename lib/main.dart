import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector/ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestMicPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

Future<void> requestMicPermission() async {
  final status = await Permission.microphone.request();

  if (!status.isGranted) {
    throw Exception("Microphone permission denied");
  }
}
