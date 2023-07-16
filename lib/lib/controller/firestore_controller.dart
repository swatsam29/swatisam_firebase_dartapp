import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lesson3/model/constant.dart';
import 'package:lesson3/model/photo_memo.dart';

class FirestoreController {
  static Future<String> addPhotoMemo({
    required PhotoMemo photoMemo,
  }) async {
    DocumentReference ref = await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .add(photoMemo.toFirestoreDoc());
    return ref.id;
  }

  static Future<List<PhotoMemo>> getPhotoMemoList({
    required String email,
  }) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .where(DocKeyPhotoMemo.createBy.name, isEqualTo: email)
        .orderBy(DocKeyPhotoMemo.timestamp.name, descending: true)
        .get();

    var result = <PhotoMemo>[];
    for (var doc in querySnapshot.docs) {
      if (doc.data() != null) {
        var document = doc.data() as Map<String, dynamic>;
        var p = PhotoMemo.fromFirestoreDoc(doc: document, docId: doc.id);
        if (p != null) result.add(p);
      }
    }
    return result;
  }

  static Future<void> updatePhotoMemo(
      {required String docId,
      required Map<String, dynamic> update,
      String? email,
      void Function(List<PhotoMemo>)? onCallBack}) async {
    await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .doc(docId)
        .update(update)
        .then((_) {
      if (email != null && onCallBack != null) {
        getPhotoMemoList(email: email).then((photo) => onCallBack(photo));
      }
    });
  }

  static Future<List<PhotoMemo>> searchImages({
    required String email,
    required List<String> searchLabel,
  }) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .where(DocKeyPhotoMemo.createBy.name, isEqualTo: email)
        .where(DocKeyPhotoMemo.imageLabels.name, arrayContainsAny: searchLabel)
        .orderBy(DocKeyPhotoMemo.timestamp.name, descending: true)
        .get();

    var result = <PhotoMemo>[];
    for (var doc in querySnapshot.docs) {
      var p = PhotoMemo.fromFirestoreDoc(
        doc: doc.data() as Map<String, dynamic>,
        docId: doc.id,
      );
      if (p != null) result.add(p);
    }

    return result;
  }

  static Future<void> deleteDoc({
    required String docId,
  }) async {
    await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .doc(docId)
        .delete();
  }

  static Future<List<PhotoMemo>> getPhotoMemoListSharedWithMe({
    required String email,
  }) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection(Constant.photoMemoCollection)
        .where(DocKeyPhotoMemo.sharedwith.name, arrayContains: email)
        .orderBy(DocKeyPhotoMemo.timestamp.name, descending: true)
        .get();

    var result = <PhotoMemo>[];
    for (var doc in querySnapshot.docs) {
      if (doc.data() != null) {
        var document = doc.data() as Map<String, dynamic>;
        var p = PhotoMemo.fromFirestoreDoc(doc: document, docId: doc.id);
        if (p != null) result.add(p);
      }
    }
    return result;
  }
}
