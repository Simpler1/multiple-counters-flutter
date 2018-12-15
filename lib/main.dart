import 'package:flutter/material.dart';
import 'package:multiple_counters_flutter/bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  final Firestore firestore = Firestore();
  await firestore.settings(timestampsInSnapshotsEnabled: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiple counters',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: BottomNavigation(),
    );
  }
}
