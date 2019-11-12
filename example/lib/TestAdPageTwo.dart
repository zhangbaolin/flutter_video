import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:ijkplayer_example/widget/controller_widget_builder.dart';

import 'package:orientation/orientation.dart';

class TestAdPageTwo extends StatefulWidget {
  @override
  _TestAdPageTwoState createState() => _TestAdPageTwoState();
}

class _TestAdPageTwoState extends State<TestAdPageTwo> with WidgetsBindingObserver {
  bool isSeeHWidget = true;
  IjkMediaController controller = IjkMediaController(isNomal: true);

  IjkMediaController adcontroller = IjkMediaController(isNomal: true);
  Timer _timer; //让视频播放器加载完成后处于暂停状态。
  Timer _adcomplateTimer; //用来循环判断广告是否播放完毕
  bool isSeeAd = false;
  @override
  void initState() {
    super.initState();
    controller.setNetworkDataSource(
        "xxx.mp4",
        autoPlay: true);
    adcontroller.setAssetDataSource("assets/video0.mp4", autoPlay: true);
    _timer = Timer.periodic(Duration(microseconds: 100), (timer) {
      //  print("当前的播放状态：${controller.ijkStatus}");
      if (controller.videoInfo != null) {
        if (controller.videoInfo.duration != null &&
            controller.videoInfo.duration != 0) {
          controller.pause();
        }
      }
    });

    _adcomplateTimer = Timer.periodic(Duration(microseconds: 100), (timer) {
      //  print("当前的播放状态：${controller.ijkStatus}");
      if (adcontroller != null &&
          adcontroller.videoInfo != null &&
          adcontroller.ijkStatus == IjkStatus.complete) {
        _timer.cancel();
        _timer = null;
        adcontroller.pause();
        controller.play();
        if (mounted) {
          setState(() {
            isSeeAd = true;
          });
        }
        _adcomplateTimer.cancel();
        _adcomplateTimer = null;
      }
    });
  }

  void setPro() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(

      //   title: Text('测试'),
      // ),

      body: Container(
        child: Container(
          padding: EdgeInsets.only(top: 0),
          child: Stack(
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: IjkPlayer(
                  mediaController: controller,
                  controllerWidgetBuilder: (mediaController) {
                    return defaultBuildIjkControllerWidget(mediaController);
                  },
                ),
              ),
              Offstage(
                offstage: isSeeAd,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 250,
                  child: IjkPlayer(
                    mediaController: adcontroller,
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
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    if (Platform.isIOS) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    }
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    if (controller != null) {
      controller.dispose();
    }
    if (adcontroller != null) {
      adcontroller.dispose();
    }
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    if (_adcomplateTimer != null) {
      _adcomplateTimer.cancel();
      _adcomplateTimer = null;
    }
    super.dispose();
  }
}
