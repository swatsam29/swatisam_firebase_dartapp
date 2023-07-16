import 'package:cloud_firestore/cloud_firestore.dart';

void someFunction() async {
  var db = FirebaseFirestore.instance;

  final user = <String, dynamic>{
    "first": "Ada",
    "last": "Lovelace",
    "born": 1815
  };
  try {
    DocumentReference doc = await db.collection("users").add(user);
    print('DocumentSnapshot added with ID: ${doc.id}');
  } catch (e) {
    //handle error cases with e
  }

  //db.collection("users").add(user).then((DocumentReference doc) =>
  //  print('DocumentSnapshot added with ID: ${doc.id}')).catchErr(function);
}
