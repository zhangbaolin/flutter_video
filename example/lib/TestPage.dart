import 'package:flutter/material.dart';
import 'package:flutter_video/flutter_video.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  IjkMediaController controller;
  bool isSeeHWidget = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); //添加观察者
    controller = IjkMediaController();
    controller.setAssetDataSource('assets/video0.mp4', autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('测试'),
      ),
      body: Container(
        child: Center(
            child: AspectRatio(
          aspectRatio: 3 / 2,
          child: IjkPlayer(
            mediaController: controller,
          ),
        )),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: // 应用程序可见，前台
        print('OnResume()');

        break;
      case AppLifecycleState.paused: // 应用程序不可见，后台
        print('OnPaused()');

        break;
      case AppLifecycleState.suspending: // 申请将暂时暂停
        break;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this); //销毁观察者
    super.dispose();
  }
}
