import 'package:flutter/material.dart';

class CommentScreen extends StatefulWidget {
  static const routeName = '/CommentScreen';

  const CommentScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CommentState();
  }
}

class _CommentState extends State<CommentScreen> {
  late _Controller con;

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
        title: const Text('Comment'),
      ),
      body: const Text('Comment'),
    );
  }
}

class _Controller {
  _CommentState state;
  _Controller(this.state);
}
