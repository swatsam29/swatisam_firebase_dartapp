// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesson3/controller/cloudstorage_controller.dart';
import 'package:lesson3/controller/firestore_controller.dart';
import 'package:lesson3/controller/ml_controller.dart';
import 'package:lesson3/model/constant.dart';
import 'package:lesson3/model/photo_memo.dart';
import 'package:lesson3/viewscreen/view/view_util.dart';

class AddPhotoMemoScreen extends StatefulWidget {
  static const routeName = '/addPhotoMemoScreen';

  final User user;
  final List<PhotoMemo> photoMemoList;

  const AddPhotoMemoScreen({
    required this.user,
    required this.photoMemoList,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AddPhotoMemoState();
  }
}

class _AddPhotoMemoState extends State<AddPhotoMemoScreen> {
  late _Controller con;
  var formKey = GlobalKey<FormState>();
  File? photo;

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add A New Memo'),
        actions: [
          IconButton(
            onPressed: con.save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
            child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: photo == null
                      ? const FittedBox(
                          child: Icon(Icons.photo_library),
                        )
                      : Image.file(photo!),
                ),
                Positioned(
                  right: 0.0,
                  bottom: 0.0,
                  child: Container(
                    color: Colors.blue[200],
                    child: PopupMenuButton(
                      onSelected: con.getPhoto,
                      itemBuilder: (context) => [
                        for (var source in PhotoSource.values)
                          PopupMenuItem(
                            value: source,
                            child: Text(source.name.toUpperCase()),
                          )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0.0,
                  bottom: 0.0,
                  child: con.progressMessage == null
                      ? const SizedBox(
                          height: 1.0,
                        )
                      : Container(
                          color: Colors.blue[200],
                          child: Text(
                            con.progressMessage!,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                ),
              ],
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'Title'),
              autocorrect: true,
              validator: PhotoMemo.validateTitle,
              onSaved: con.saveTitle,
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'Memo'),
              autocorrect: true,
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              validator: PhotoMemo.validateMemo,
              onSaved: con.saveMemo,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  hintText: 'Shared with (email list seperated by space , : )'),
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              maxLines: 2,
              validator: PhotoMemo.validateSharedWith,
              onSaved: con.saveSharedWith,
            ),
          ],
        )),
      ),
    );
  }
}

class _Controller {
  _AddPhotoMemoState state;
  PhotoMemo tempMemo = PhotoMemo();
  String? progressMessage;

  _Controller(this.state);

  void getPhoto(PhotoSource source) async {
    try {
      var imageSource = source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      XFile? image = await ImagePicker().pickImage(source: imageSource);
      if (image == null) return; //canceled
      state.render(() => state.photo = File(image.path));
    } catch (e) {
      if (Constant.devMode) print('============ failed to get pic: $e');
      showSnackBar(context: state.context, message: 'Failed to get pic: $e');
    }
  }

  void save() async {
    FormState? currentState = state.formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }
    if (state.photo == null) {
      showSnackBar(context: state.context, message: 'Photo not selected');
      return;
    }
    currentState.save();

    startCircularProgress(state.context);
    try {
      Map result = await CloudStorageController.uploadPhotoFile(
        photo: state.photo!,
        uid: state.widget.user.uid,
        listener: (int progress) {
          state.render(() {
            if (progress == 100) {
              progressMessage = null;
            } else {
              progressMessage = 'Uploading: $progress %';
            }
          });
        },
      );
      tempMemo.photoFilename = result[ArgKey.filename];
      tempMemo.photoURL = result[ArgKey.downloadURL];
      tempMemo.imageLabels =
          await GoogleMlController.getImageLabels(photo: state.photo!);
      tempMemo.createBy = state.widget.user.email!;
      tempMemo.timestamp = DateTime.now();

      String docId =
          await FirestoreController.addPhotoMemo(photoMemo: tempMemo);
      tempMemo.docId = docId;

      state.widget.photoMemoList.insert(0, tempMemo);

      stopCircularProgress(state.context);

      Navigator.of(state.context).pop();
    } catch (e) {
      stopCircularProgress(state.context);
      if (Constant.devMode) print('************ uploadFile error: $e');
      showSnackBar(context: state.context, message: 'uploadFile error: $e');
    }
  }

  void saveTitle(String? value) {
    if (value != null) {
      tempMemo.title = value;
    }
  }

  void saveMemo(String? value) {
    if (value != null) {
      tempMemo.memo = value;
    }
  }

  void saveSharedWith(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      var emailList =
          value.trim().split(RegExp('(, |;| )+')).map((e) => e.trim()).toList();
      tempMemo.sharedwith = emailList;
    }
  }
}
