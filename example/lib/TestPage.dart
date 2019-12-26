import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:ijkplayer_example/widget/controller_widget_builder.dart';

import 'package:orientation/orientation.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  bool isSeeHWidget = true;
  IjkMediaController controller = IjkMediaController(isNomal: true);

  Timer _timer;
  @override
  void initState() {
    super.initState();
    //  SystemChrome.setEnabledSystemUIOverlays([]);
    WidgetsBinding.instance.addObserver(this); //添加观察者
 
    setPro();
    _timer = Timer.periodic(Duration(microseconds: 100), (timer) {
    //  print("当前的播放状态：${controller.ijkStatus}");
      if (controller.ijkStatus == IjkStatus.playing &&
          controller.videoInfo.currentPosition > 0) {
        controller?.seekTo(200);
        controller.isInit;
        _timer.cancel();
        _timer = null;
      }
    });
  }

  void setPro() async {
    await controller.setNetworkDataSource(
        "https://file.djbar888.online/index.php/file?name=jp_n/031619-822.mp4",
        autoPlay: true);
   // await controller?.seekTo(200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(

      //   title: Text('测试'),
      // ),

      body: Container(
        child: Container(
          padding: EdgeInsets.only(top: 0),
          child: ListView(
            children: <Widget>[
              SafeArea(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 250,
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
                    controllerWidgetBuilder: (mediaController) {
                      return defaultBuildIjkControllerWidget(mediaController);
                    },
                  ),
                ),
              )
            ],
          ),
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
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    if (Platform.isIOS) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    }
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
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
