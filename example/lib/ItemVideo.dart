import 'package:flutter_video/flutter_video.dart';
import 'package:flutter/material.dart';

class ItemVideo extends StatefulWidget {
  final IjkMediaController controller;
  ItemVideo({Key key, @required this.controller}) : super(key: key);
  @override
  _ItemVideoState createState() => _ItemVideoState(controller);
}

class _ItemVideoState extends State<ItemVideo> {
  final IjkMediaController controller;
  _ItemVideoState(this.controller);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Container(
            child: IjkPlayer(
              mediaController: controller,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (controller != null) {
      controller.dispose();
    }
    super.dispose();
  }
}
