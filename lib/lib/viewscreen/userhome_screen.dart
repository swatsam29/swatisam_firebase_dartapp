// ignore_for_file: avoid_print, invalid_use_of_protected_member, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lesson3/controller/auth_controller.dart';
import 'package:lesson3/controller/cloudstorage_controller.dart';
import 'package:lesson3/controller/firestore_controller.dart';
import 'package:lesson3/model/constant.dart';
import 'package:lesson3/model/photo_memo.dart';
import 'package:lesson3/viewscreen/addphotomemo_screen.dart';
import 'package:lesson3/viewscreen/detailedview_screen.dart';
import 'package:lesson3/viewscreen/favourite_screen.dart';
import 'package:lesson3/viewscreen/sharedwith_screen.dart';
import 'package:lesson3/viewscreen/view/view_util.dart';
import 'package:lesson3/viewscreen/view/webimage.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen(
      {required this.user, required this.photoMemoList, Key? key})
      : super(key: key);
  static const routeName = '/userHomeScreen';

  final User user;
  final List<PhotoMemo> photoMemoList;

  @override
  State<StatefulWidget> createState() {
    return _UserHomeState();
  }
}

class _UserHomeState extends State<UserHomeScreen> {
  late _Controller con;
  late String email;
  var formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    email = widget.user.email ?? 'No email';
  }

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Home '),
          actions: [
            con.selected.isEmpty
                ? Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Search(empty for all)',
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          autocorrect: true,
                          onSaved: con.saveSearchKey,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: con.cancel,
                  ),
            con.selected.isEmpty
                ? IconButton(
                    onPressed: con.search,
                    icon: const Icon(Icons.search),
                  )
                : IconButton(
                    onPressed: con.delete,
                    icon: const Icon(Icons.delete),
                  ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: const Icon(
                  Icons.person,
                  size: 70.0,
                ),
                accountName: const Text('no profile'),
                accountEmail: Text(email),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Shared With'),
                onTap: con.sharedWith,
              ),
              ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favourite'),
                  onTap: con.myFavorite),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('sign out'),
                onTap: con.signOut,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: con.addButton,
          child: const Icon(Icons.add),
        ),
        body: con.photoMemoList.isEmpty
            ? Text(
                'No PhotoMemo found!',
                style: Theme.of(context).textTheme.headline6,
              )
            : ListView.builder(
                itemCount: con.photoMemoList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    selected: con.selected.contains(index),
                    selectedTileColor: Colors.blue[100],
                    //tileColor: Colors.grey,
                    leading: WebImage(
                      url: con.photoMemoList[index].photoURL,
                      context: context,
                    ),
                    trailing: Column(
                      children: [
                        IconButton(
                          icon: Icon(
                              con.photoMemoList[index].isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: con.photoMemoList[index].isFavorite
                                  ? Colors.red
                                  : Colors.grey),
                          onPressed: () {
                            con.favourite(
                                docId: con.photoMemoList[index].docId!,
                                value: !con.photoMemoList[index].isFavorite);
                          },
                        ),
                      ],
                    ),
                    title: Text(con.photoMemoList[index].title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          con.photoMemoList[index].memo.length >= 40
                              ? '${con.photoMemoList[index].memo.substring(0, 40)}...'
                              : con.photoMemoList[index].memo,
                        ),
                        Text(
                            'Created By: ${con.photoMemoList[index].createBy}'),
                        Text(
                            'Shared With: ${con.photoMemoList[index].sharedwith}'),
                        Text(
                            'TimeStamp: ${con.photoMemoList[index].timestamp}'),
                      ],
                    ),
                    onTap: () => con.onTap(index),
                    onLongPress: () => con.onLongPress(index),
                  );
                },
              ),
      ),
    );
  }
}

class _Controller {
  _UserHomeState state;
  late List<PhotoMemo> photoMemoList;
  String? searchKeyString;
  List<int> selected = [];

  _Controller(this.state) {
    photoMemoList = state.widget.photoMemoList;
  }

  void favourite({required bool value, required String docId}) async {
    startCircularProgress(state.context);
    await FirestoreController.updatePhotoMemo(
        update: {'isFavorite': value},
        docId: docId,
        email: state.email,
        onCallBack: (value) {
          photoMemoList.clear();
          state.setState(() {
            state.widget.photoMemoList.clear();
          });
          Future.delayed(const Duration(milliseconds: 750));
          state.setState(() {
            photoMemoList = value;
          });
        }).whenComplete(() {
      stopCircularProgress(state.context);
    });
  }

  void myFavorite() async {
    try {
      List<PhotoMemo> photoMemoList =
          await FirestoreController.getPhotoMemoListSharedWithMe(
        email: state.email,
      );
      // ignore: use_build_context_synchronously
      await Navigator.pushNamed(
        state.context,
        FavouriteScreen.routeName,
        arguments: {
          ArgKey.photoMemoList: photoMemoList,
          ArgKey.user: state.widget.user,
        },
      );
    } catch (e) {
      print('ERROR===================$e');
    }
  }

  void sharedWith() async {
    try {
      List<PhotoMemo> photoMemoList =
          await FirestoreController.getPhotoMemoListSharedWithMe(
        email: state.email,
      );
      // ignore: use_build_context_synchronously
      await Navigator.pushNamed(
        state.context,
        SharedWithScreen.routeName,
        arguments: {
          ArgKey.photoMemoList: photoMemoList,
          ArgKey.user: state.widget.user,
        },
      );
      // ignore: use_build_context_synchronously
      Navigator.of(state.context).pop(); //push in the drawer
    } catch (e) {
      if (Constant.devMode) print('===== get SharedWith list error : $e');
      showSnackBar(
        context: state.context,
        message: 'Failed to get SharedWith list : $e',
      );
    }
  }

  void cancel() {
    state.render(() => selected.clear());
  }

  void delete() async {
    //delete photomemos in photomemolist &&firestore/storage
    startCircularProgress(state.context);
    selected.sort();
    for (int i = selected.length - 1; i >= 0; i--) {
      try {
        PhotoMemo p = photoMemoList[selected[i]];
        await FirestoreController.deleteDoc(docId: p.docId!);
        await CloudStorageController.deleteFile(filename: p.photoFilename);
        state.render(() {
          photoMemoList.removeAt(selected[i]);
        });
      } catch (e) {
        if (Constant.devMode) print('==== failed to delete: $e');
        showSnackBar(
          context: state.context,
          seconds: 20,
          message: 'Failed! SignOut and IN again to get updated list\n$e',
        );
        break; //quit further processing
      }
    }
    state.render(() => selected.clear());
    stopCircularProgress(state.context);
  }

  void saveSearchKey(String? value) {
    searchKeyString = value;
  }

  void search() async {
    FormState? currentState = state.formKey.currentState;
    if (currentState == null) return;
    currentState.save();

    List<String> keys = [];
    if (searchKeyString != null) {
      var tokens = searchKeyString!.split(RegExp('(,| )+')).toList();
      for (var t in tokens) {
        if (t.trim().isNotEmpty) keys.add(t.trim().toLowerCase());
      }
    }
    startCircularProgress(state.context);

    try {
      late List<PhotoMemo> results;
      if (keys.isEmpty) {
        results =
            await FirestoreController.getPhotoMemoList(email: state.email);
      } else {
        results = await FirestoreController.searchImages(
          email: state.email,
          searchLabel: keys,
        );
      }
      stopCircularProgress(state.context);
      state.render(() {
        photoMemoList = results;
      });
    } catch (e) {
      stopCircularProgress(state.context);
      if (Constant.devMode) print('===== failed to search : $e');
      showSnackBar(
          context: state.context,
          seconds: 20,
          message: 'failed to search : $e');
    }
  }

  void addButton() async {
    //navigate to add photo memo screen
    await Navigator.pushNamed(state.context, AddPhotoMemoScreen.routeName,
        arguments: {
          ArgKey.user: state.widget.user,
          ArgKey.photoMemoList: photoMemoList,
        });
    state.render(() {}); // re render the screen
  }

  Future<void> signOut() async {
    try {
      await AuthController.signOut();
    } catch (e) {
      if (Constant.devMode) print('=============== signout error: $e');
      showSnackBar(context: state.context, message: 'signout error: $e');
    }
    Navigator.of(state.context).pop(); //close the drawer
    Navigator.of(state.context).pop(); //return to start screen
  }

  void onTap(int index) async {
    if (selected.isNotEmpty) {
      onLongPress(index);
      return;
    }
    await Navigator.pushNamed(state.context, DetailedViewScreen.routeName,
        arguments: {
          ArgKey.user: state.widget.user,
          ArgKey.onePhotoMemo: photoMemoList[index],
        });
    state.render(() {});
  }

  void onLongPress(int index) {
    state.render(() {
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
    });
  }
}
