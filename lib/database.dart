import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Counter {
  Counter({this.id, this.value});
  int id;
  int value;
}

abstract class Database {
  Future<void> createCounter();
  Future<void> setCounter(Counter counter);
  Future<void> deleteCounter(Counter counter);
  Stream<List<Counter>> countersStream();
}

//
// Realtime Database
class AppDatabase implements Database {
  Future<void> createCounter() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    Counter counter = Counter(id: now, value: 0);
    await setCounter(counter);
  }

  Future<void> setCounter(Counter counter) async {
    DatabaseReference databaseReference = _databaseReference(counter);
    await databaseReference.set(counter.value);
  }

  Future<void> deleteCounter(Counter counter) async {
    DatabaseReference databaseReference = _databaseReference(counter);
    await databaseReference.remove();
  }

  Stream<List<Counter>> countersStream() {
    return _DatabaseStream<List<Counter>>(
      apiPath: rootPath,
      parser: _DatabaseCountersParser(),
    ).stream;
  }

  DatabaseReference _databaseReference(Counter counter) {
    var path = '$rootPath/${counter.id}';
    return FirebaseDatabase.instance.reference().child(path);
  }

  static final String rootPath = 'counters';
}

class _DatabaseStream<T> {
  _DatabaseStream({String apiPath, DatabaseNodeParser<T> parser}) {
    FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
    DatabaseReference databaseReference = firebaseDatabase.reference().child(apiPath);
    var eventStream = databaseReference.onValue;
    stream = eventStream.map((event) => parser.parse(event));
  }

  Stream<T> stream;
}

abstract class DatabaseNodeParser<T> {
  T parse(Event event);
}

class _DatabaseCountersParser implements DatabaseNodeParser<List<Counter>> {
  List<Counter> parse(Event event) {
    Map<dynamic, dynamic> values = event.snapshot.value;
    if (values != null) {
      Iterable<String> keys = values.keys.cast<String>();

      var counters = keys.map((key) {
        // print('$key  ${values[key]}');
        return Counter(id: int.parse(key), value: values[key]);
      }).toList();
      counters.sort((lhs, rhs) => rhs.id.compareTo(lhs.id));
      return counters;
    } else {
      return [];
    }
  }
}

//
// Cloud Firestore
class AppFirestore implements Database {
  Future<void> createCounter() async {
    int now = DateTime.now().millisecondsSinceEpoch;
    Counter counter = Counter(id: now, value: 0);
    await setCounter(counter);
  }

  Future<void> setCounter(Counter counter) async {
    _documentReference(counter).setData({
      'value': counter.value,
    });
  }

  Future<void> deleteCounter(Counter counter) async {
    _documentReference(counter).delete();
  }

  Stream<List<Counter>> countersStream() {
    return _FirestoreStream<List<Counter>>(
      apiPath: rootPath,
      parser: FirestoreCountersParser(),
    ).stream;
  }

  DocumentReference _documentReference(Counter counter) {
    return Firestore.instance.collection(rootPath).document('${counter.id}');
  }

  static final String rootPath = 'counters';
}

class _FirestoreStream<T> {
  _FirestoreStream({String apiPath, FirestoreNodeParser<T> parser}) {
    CollectionReference collectionReference = Firestore.instance.collection(apiPath);
    Stream<QuerySnapshot> snapshots = collectionReference.snapshots();

    // snapshots.forEach((snapshot) {
    //   snapshot.documentChanges.forEach((change) {
    //     print(change.type);
    //     print(change.document.data);
    //   });
    // });

    stream = snapshots.map((snapshot) => parser.parse(snapshot));
  }

  Stream<T> stream;
}

abstract class FirestoreNodeParser<T> {
  T parse(QuerySnapshot querySnapshot);
}

class FirestoreCountersParser extends FirestoreNodeParser<List<Counter>> {
  List<Counter> parse(QuerySnapshot querySnapshot) {
    // print('querySnapshot hashCode: ${querySnapshot.hashCode}');
    var counters = querySnapshot.documents.map((documentSnapshot) {
      // print('${documentSnapshot.documentID} ${documentSnapshot['value']}');
      return Counter(
        id: int.parse(documentSnapshot.documentID),
        value: documentSnapshot['value'],
      );
    }).toList();
    counters.sort((lhs, rhs) => rhs.id.compareTo(lhs.id));
    return counters;
  }
}
