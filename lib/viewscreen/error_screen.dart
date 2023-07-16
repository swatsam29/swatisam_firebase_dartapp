import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorScreen(this.errorMessage, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Error'),
      ),
      body: Text(
        'Internal error has occured.\n Restart this app! \n $errorMessage',
        style: const TextStyle(color: Colors.red, fontSize: 36.0),
      ),
    );
  }
}
