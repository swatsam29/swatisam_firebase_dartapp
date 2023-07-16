// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';

class WebImage extends Image {
  WebImage({
    required String url,
    required BuildContext context,
    double height = 200.0,
    Key? key,
  }) : super.network(url, height: height, key: key, errorBuilder:
            (BuildContext context, Object exception, StackTrace? StackTrace) {
          print('========= web image error: $exception');
          return Icon(
            Icons.error,
            size: height,
          );
        }, loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProcess) {
          if (loadingProcess == null) {
            return child;
          } else {
            return CircularProgressIndicator(
              value: loadingProcess.expectedTotalBytes != null
                  ? loadingProcess.cumulativeBytesLoaded /
                      loadingProcess.expectedTotalBytes!
                  : null,
            );
          }
        });
}
