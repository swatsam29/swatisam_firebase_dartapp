// ignore_for_file: invalid_use_of_protected_member

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lesson3/controller/firestore_controller.dart';
import 'package:lesson3/model/constant.dart';
import 'package:lesson3/model/photo_memo.dart';
import 'package:lesson3/viewscreen/detailedview_screen.dart';
import 'package:lesson3/viewscreen/view/view_util.dart';
import 'package:lesson3/viewscreen/view/webimage.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen(
      {Key? key, required this.user, required this.phoneMemoList})
      : super(key: key);
  final User user;
  final List<PhotoMemo> phoneMemoList;
  static const routeName = '/favouriteScreen';

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  late _Controller con;

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add To Favorite'),
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
                  trailing: IconButton(
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
                  title: Text(con.photoMemoList[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        con.photoMemoList[index].memo.length >= 40
                            ? '${con.photoMemoList[index].memo.substring(0, 40)}...'
                            : con.photoMemoList[index].memo,
                      ),
                      Text('Created By: ${con.photoMemoList[index].createBy}'),
                      Text(
                          'Shared With: ${con.photoMemoList[index].sharedwith}'),
                      Text('TimeStamp: ${con.photoMemoList[index].timestamp}'),
                    ],
                  ),
                  onTap: () => con.onTap(index),
                  //onLongPress: () => con.onLongPress(index),
                );
              },
            ),
    );
  }
}

class _Controller {
  _FavouriteScreenState state;
  late List<PhotoMemo> photoMemoList;
  List<int> selected = [];

  _Controller(this.state) {
    photoMemoList =
        state.widget.phoneMemoList.where((value) => value.isFavorite).toList();
  }

  void onTap(int index) async {
    await Navigator.pushNamed(state.context, DetailedViewScreen.routeName,
        arguments: {
          ArgKey.user: state.widget.user,
          ArgKey.onePhotoMemo: photoMemoList[index],
        });
  }

  void favourite({required bool value, required String docId}) async {
    startCircularProgress(state.context);
    await FirestoreController.updatePhotoMemo(
        update: {'isFavorite': value},
        docId: docId,
        email: state.widget.user.email,
        onCallBack: (value) {
          photoMemoList.clear();
          Future.delayed(const Duration(milliseconds: 750));
          state.setState(() {
            state.widget.phoneMemoList.clear();
          });
          Future.delayed(const Duration(milliseconds: 750));
          state.setState(() {
            photoMemoList = value.where((val) => val.isFavorite).toList();
          });
        }).whenComplete(() {
      stopCircularProgress(state.context);
    });
  }
}
