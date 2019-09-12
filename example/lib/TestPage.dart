import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  bool isSeeHWidget = true;
  IjkMediaController controller = IjkMediaController();
  Timer _timer;
  @override
  void initState() {
    super.initState();
    //  SystemChrome.setEnabledSystemUIOverlays([]);
    WidgetsBinding.instance.addObserver(this); //添加观察者
    controller.setNetworkDataSource(
        "http://multimedia.lx8886.com/upload/20190908051310.mp4",
        autoPlay: true);

    // _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    //   print("当前的播放状态：${controller.ijkStatus}");
    //   if (controller.ijkStatus == IjkStatus.playing) {
    //     setPro();
    //     _timer.cancel();
    //     _timer = null;
    //   }
    // });
  }

  void setPro() async {
    await controller.seekToProgress(0.5);
  }

  //http://multimedia.lx8886.com/upload/20190908051310.mp4
//http://app.12321hc.com/app/video0.mp4
//rtmp://192.168.1.56/live/stream1
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(

      //   title: Text('测试'),
      // ),
      body: Container(
        child: Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 3 / 2,
                  child: IjkPlayer(
                    mediaController: controller,
                    // textureBuilder: (context, mediaController, info) {

                    //   return Container(
                    //     height: 300,
                    //     width: MediaQuery.of(context).size.width,
                    //     child: IjkPlayer(
                    //       mediaController: mediaController,
                    //     ),
                    //   );
                    // },
                    // statusWidgetBuilder: (context, mediaController, stte) {
                    //   return Container(
                    //     margin: EdgeInsets.only(top: 50),
                    //     child:
                    //         Text("data", style: TextStyle(color: Colors.white)),
                    //   );
                    // },
                  ),
                ),
              ],
            ),
          ],
        ),
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
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this); //销毁观察者
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }
}
