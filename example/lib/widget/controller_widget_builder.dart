import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:ijkplayer_example/widget/fullscreen_route.dart';
import 'package:ijkplayer_example/widget/progress_bar.dart';
import 'package:ijkplayer_example/widget/time_helper.dart';
import 'package:ijkplayer_example/widget/ui_helper.dart';

import 'package:orientation/orientation.dart';
import 'package:screen/screen.dart';

part 'full_screen.part.dart';

/**
 * 自定义控制器页面
 */
/// Using mediaController to Construct a Controller UI
typedef Widget IJKControllerWidgetBuilder(IjkMediaController controller);

/// default create IJK Controller UI
Widget defaultBuildIjkControllerWidget(IjkMediaController controller,
    {String adimageUrl,
    String adTitle,
    double adrevealTime,
    double addisappearTime,
    bool isShowAD,
    bool isShowRatio,
    String videoTitleTxT}) {
  return DefaultIJKControllerWidget(
    controller: controller,
    adimageUrl: adimageUrl == null ? "assets/asd.png" : adimageUrl,
    adTitle: adTitle == null ? "assets/asd.png" : adimageUrl,
    adrevealTime: adrevealTime == null ? 50 : adrevealTime,
    addisappearTime: addisappearTime == null ? 100 : addisappearTime,
    isShowAD: isShowAD == null ? false : isShowAD,
    isShowRatio: isShowRatio == null ? false : isShowRatio,
    videoTitleTxT: videoTitleTxT == null ? "视频标题" : videoTitleTxT,
    fullscreenControllerWidgetBuilder: (ctl) =>
        buildFullscreenMediaController(ctl),
  );
}

/// Default Controller Widget
///
/// see [IjkPlayer] and [IJKControllerWidgetBuilder]
class DefaultIJKControllerWidget extends StatefulWidget {
  final IjkMediaController controller;

  /// If [doubleTapPlay] is true, can double tap to play or pause media.
  final bool doubleTapPlay;

  /// If [verticalGesture] is false, vertical gesture will be ignored.
  final bool verticalGesture;

  /// If [horizontalGesture] is false, horizontal gesture will be ignored.
  final bool horizontalGesture;

  /// Controlling [verticalGesture] is controlling system volume or media volume.
  final VolumeType volumeType;

  final bool playWillPauseOther;

  /// Control whether there is a full-screen button.
  final bool showFullScreenButton;

  /// The current full-screen button style should not be changed by users.
  final bool currentFullScreenState;

  final IJKControllerWidgetBuilder fullscreenControllerWidgetBuilder;

  /// See [FullScreenType]
  final FullScreenType fullScreenType;
  //新添加控制器属性   广告用
  final String adimageUrl; //广告图片
  final String adTitle; //广告标题
  final double adrevealTime; //显示时间
  final double addisappearTime; //消失时间
  final bool isShowAD; //是否显示广告  true  //显示  false 隐藏
  final bool isShowRatio; //是否显示分辨率的选项  true  //显示  false 隐藏
  final String videoTitleTxT; //视频标题

  /// The UI of the controller.
  const DefaultIJKControllerWidget(
      {Key key,
      @required this.controller,
      this.doubleTapPlay = false,
      this.verticalGesture = true,
      this.horizontalGesture = true,
      this.volumeType = VolumeType.system,
      this.playWillPauseOther = true,
      this.currentFullScreenState = false,
      this.showFullScreenButton = true,
      this.fullscreenControllerWidgetBuilder,
      this.fullScreenType = FullScreenType.rotateBox,
      this.adimageUrl = "assets/asd.png",
      this.adTitle = "嗯嗯这是广告",
      this.adrevealTime = 10,
      this.addisappearTime = 50,
      this.isShowAD = false,
      this.isShowRatio = true,
      this.videoTitleTxT = "视频标题"})
      : super(key: key);

  @override
  _DefaultIJKControllerWidgetState createState() =>
      _DefaultIJKControllerWidgetState();

  DefaultIJKControllerWidget copyWith(
      {Key key,
      IjkMediaController controller,
      bool doubleTapPlay,
      bool verticalGesture,
      bool horizontalGesture,
      VolumeType volumeType,
      bool playWillPauseOther,
      bool currentFullScreenState,
      bool showFullScreenButton,
      IJKControllerWidgetBuilder fullscreenControllerWidgetBuilder,
      FullScreenType fullScreenType,
      String adimageUrl,
      String adTitle,
      double adrevealTime,
      double addisappearTime,
      bool isShowAD,
      bool isShowRatio,
      String videoTitleTxT}) {
    return DefaultIJKControllerWidget(
      controller: controller ?? this.controller,
      doubleTapPlay: doubleTapPlay ?? this.doubleTapPlay,
      fullscreenControllerWidgetBuilder: fullscreenControllerWidgetBuilder ??
          this.fullscreenControllerWidgetBuilder,
      horizontalGesture: horizontalGesture ?? this.horizontalGesture,
      currentFullScreenState:
          currentFullScreenState ?? this.currentFullScreenState,
      key: key,
      volumeType: volumeType ?? this.volumeType,
      playWillPauseOther: playWillPauseOther ?? this.playWillPauseOther,
      showFullScreenButton: showFullScreenButton ?? this.showFullScreenButton,
      verticalGesture: verticalGesture ?? this.verticalGesture,
      fullScreenType: fullScreenType ?? this.fullScreenType,
      adimageUrl: adimageUrl ?? this.adimageUrl,
      adTitle: adTitle ?? this.adTitle,
      adrevealTime: adrevealTime ?? this.adrevealTime,
      addisappearTime: addisappearTime ?? this.addisappearTime,
      isShowAD: isShowAD ?? this.isShowAD,
      isShowRatio: isShowRatio ?? this.isShowRatio,
      videoTitleTxT: videoTitleTxT ?? this.videoTitleTxT,
    );
  }
}

class _DefaultIJKControllerWidgetState extends State<DefaultIJKControllerWidget>
    with TickerProviderStateMixin {
  IjkMediaController get controller => widget.controller;

  GlobalKey currentKey = GlobalKey();

  bool _isShow = false;

  set isShow(bool value) {
    _isShow = value;
    setState(() {});
    if (value == true) {
      controller.refreshVideoInfo();
    }
  }

  bool get isShow => _isShow;

  Timer progressTimer;

  StreamSubscription controllerSubscription;
//新添加计时器  控制层的显示与隐藏   默认控制层显示后  5秒钟自动隐藏
  Timer bottomBarTimer;
  Timer firstbottomTimer;
  //新添加属性
  bool isVoiceNone = false;
  bool isShowad = false; //是否显示广告
  bool isSeeselectredou = true;

  //添加广告动画
  //动画控制器
  AnimationController animationController;
  Animation<Offset> animation;
  //广告显示时间 广告弹出时间  广告消失时间
  Timer adbeginTimer;
  Timer adendTimer;
  var value;
  String videoRatioTxT = "高清"; //分辨率设置
  Widget showIconWidget;

  Timer _fulltimer;
  bool isSeeFirstLoading = false;
  @override
  void initState() {
    super.initState();
    showIconWidget = null;
    startTimer();
    controllerSubscription =
        controller.textureIdStream.listen(_onTextureIdChange);
    isShowbottomBar();
    //保持屏幕常亮
    Screen.keepOn(true);
  }

  //是否显示底部
  void isShowbottomBar() {
    firstbottomTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!isShow) {
        setState(() {
          isShow = true;
        });
      }
      if (firstbottomTimer != null) {
        firstbottomTimer.cancel();
        firstbottomTimer = null;
      }
    });
  }

  void _onTextureIdChange(int textureId) {
    if (textureId != null) {
      startTimer();
    } else {
      stopTimer();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    if (bottomBarTimer != null) {
      bottomBarTimer.cancel();
      bottomBarTimer = null;
    }
    if (firstbottomTimer != null) {
      firstbottomTimer.cancel();
      firstbottomTimer = null;
    }

    if (animationController != null) {
      animationController.dispose();
    }

    if (adbeginTimer != null) {
      adbeginTimer.cancel();
      adbeginTimer = null;
    }
    if (adendTimer != null) {
      adendTimer.cancel();
      adendTimer = null;
    }
    if (_fulltimer != null) {
      _fulltimer?.cancel();
      _fulltimer = null;
    }
    //取消屏幕活性
    Screen.keepOn(false);
    controllerSubscription.cancel();
    stopTimer();
    IjkManager.resetBrightness();
    // 强制竖屏
    print("视频控制器销毁了");
    if (widget.currentFullScreenState) {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      if (Platform.isIOS) {
        OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
      }
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    super.dispose();
  }

  void startTimer() {
    if (controller.textureId == null) {
      return;
    }

    progressTimer?.cancel();
    progressTimer = Timer.periodic(Duration(milliseconds: 350), (timer) {
      //   LogUtils.verbose("timer will call refresh info");
      controller.refreshVideoInfo();
      if (controller != null) {
        if (controller.ijkStatus == IjkStatus.complete ||
            controller.videoInfo.currentPosition ==
                controller.videoInfo.duration) {
          controller?.seekTo(0);
        }
      }
    });
  }

  void stopTimer() {
    progressTimer?.cancel();
    progressTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isNomal) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: buildContent(),
        onDoubleTap: onDoubleTap(),
        onHorizontalDragStart: wrapHorizontalGesture(_onHorizontalDragStart),
        onHorizontalDragUpdate: wrapHorizontalGesture(_onHorizontalDragUpdate),
        onHorizontalDragEnd: wrapHorizontalGesture(_onHorizontalDragEnd),
        onVerticalDragStart: wrapVerticalGesture(_onVerticalDragStart),
        onVerticalDragUpdate: wrapVerticalGesture(_onVerticalDragUpdate),
        onVerticalDragEnd: wrapVerticalGesture(_onVerticalDragEnd),
        onTap: onTap,
        key: currentKey,
      );
    } else {
      //列表的视频
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: buildContent(),
        onDoubleTap: onDoubleTap(),
        onHorizontalDragStart: wrapHorizontalGesture(_onHorizontalDragStart),
        onHorizontalDragUpdate: wrapHorizontalGesture(_onHorizontalDragUpdate),
        onHorizontalDragEnd: wrapHorizontalGesture(_onHorizontalDragEnd),
        onTap: onTap,
        key: currentKey,
      );
    }
  }

  Widget buildContent() {
    return StreamBuilder<VideoInfo>(
      stream: controller.videoInfoStream,
      builder: (context, snapshot) {
        var info = snapshot.data;
        // print("视频得详情：$info");
        // print("当前播放状态：${controller?.ijkStatus}");
        if (info != null) {
          if (info?.duration == 0.0&&controller.ijkStatus!=IjkStatus.error) {
            return Container(
              color: Color.fromRGBO(0, 0, 0, 0),
              child: Offstage(
                offstage: isSeeFirstLoading,
                child: Center(
                  child: Text(
                    "正在加速缓冲中",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            );
          } else {
           isSeeFirstLoading = true;
            return Stack(
              children: <Widget>[
                Offstage(
                  offstage: isShow,
                  child: buildPortrait(info),
                ),
                Container(), //广告
                buildShowIcon(),
                // buildShowPauseIcon()
              ],
            );
          }
        } else {
          return Container();
        }
        // if (info == null || !info.hasData) {
        //   return Container(
        //     color: Color.fromRGBO(0, 0, 0, 0),
        //     child: Center(
        //       child: Text(
        //         "正在加速缓冲中",
        //         style: TextStyle(color: Colors.white, fontSize: 20),
        //       ),
        //     ),
        //   );
        // } else {
        //   if (controller.ijkStatus == IjkStatus.noDatasource) {
        //     return Container(
        //       color: Color.fromRGBO(0, 0, 0, 0),
        //       child: Center(
        //         child: Text(
        //           "正在加速缓冲中",
        //           style: TextStyle(color: Colors.white, fontSize: 20),
        //         ),
        //       ),
        //     );
        //   }
        // }

        // return Stack(
        //   children: <Widget>[
        //     Offstage(
        //       offstage: isShow,
        //       child: buildPortrait(info),
        //     ),
        //     Container(), //广告
        //     //显示声音  快进后退的
        //     buildShowIcon(),
        //     // buildShowPauseIcon()
        //   ],
        // );
      },
    );
  }

//显示声音  快进后退的
  //显示声音  快进后退的
  buildShowIcon() {
    return showIconWidget == null
        ? Container()
        : Container(
            alignment: Alignment.center,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: showIconWidget,
            ),
          );
  }

  buildShowPauseIcon() {
    return Offstage(
      offstage: true,
      child: Center(
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            iconSize: 30,
            color: Colors.black,
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              controller.playOrPause(pauseOther: widget.playWillPauseOther);
            },
          ),
        ),
      ),
    );
  }

  Widget buildPortrait(VideoInfo info) {
    return Stack(
      children: <Widget>[
        PortraitController(
            controller: controller,
            info: info,
            playWillPauseOther: widget.playWillPauseOther,
            fullScreenWidget: _buildFullScreenButton(),
            playPauseWidget: _buildPlayButton(info)),
        voiceIcon(),
        // Offstage(
        //   offstage: !widget.isShowRatio,
        //   child: videoTitle(),
        // )
      ],
    );
  }

  Widget _buildFullScreenButton() {
    if (widget.showFullScreenButton != true) {
      return Container();
    }
    var isFull = widget.currentFullScreenState;

    IJKControllerWidgetBuilder fullscreenBuilder =
        widget.fullscreenControllerWidgetBuilder ??
            (ctx) => widget.copyWith(currentFullScreenState: true);

    return GestureDetector(
      onTap: () {
        clickFullScreenBtn(isFull, fullscreenBuilder);
      },
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        child: Icon(
          isFull ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }

  _buildPlayButton(VideoInfo info) {
    return GestureDetector(
      onTap: () {
        print("哈哈哈");

        controller.playOrPause(pauseOther: widget.playWillPauseOther);
      },
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        child: Icon(
          info.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }

  clickFullScreenBtn(
      bool isFull, IJKControllerWidgetBuilder fullscreenBuilder) {
    if (isFull) {
      Navigator.pop(context);

      // 强制竖屏
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      if (Platform.isIOS) {
        OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
      }
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    } else {
      showFullScreenIJKPlayer(
        context,
        controller,
        fullscreenControllerWidgetBuilder: fullscreenBuilder,
        fullScreenType: widget.fullScreenType,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      if (Platform.isIOS) {
        OrientationPlugin.forceOrientation(DeviceOrientation.landscapeLeft);
      }
      SystemChrome.setEnabledSystemUIOverlays([]);
    }
  }

  //音量按钮
  Widget voiceIcon() {
    return Container(
      padding: EdgeInsets.only(left: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            // 设置静音
            if (isVoiceNone) {
              setState(() {
                controller.volume = 30;
                isVoiceNone = false;
              });
            } else {
              setState(() {
                controller.volume = 0;
                isVoiceNone = true;
              });
            }
          },
          child: isVoiceNone
              ? Icon(Icons.settings_voice, color: Colors.red, size: 25)
              : Icon(Icons.settings_voice, color: Colors.white, size: 25),
        ),
      ),
    );
  }

  //视频标题
  Widget videoTitle() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 40,
        color: Color.fromRGBO(0, 0, 0, 0.4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  "${widget.videoTitleTxT}",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Container(
              width: 60,
              child: PopupMenuButton(
                child: Text(
                  "$videoRatioTxT",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                tooltip: "长按提示",
                initialValue: "hot",
                padding: EdgeInsets.all(0.0),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<String>>[
                    PopupMenuItem<String>(
                      child: Text("标准"),
                      value: "bz",
                    ),
                    PopupMenuItem<String>(
                      child: Text("高清"),
                      value: "gq",
                    ),
                    PopupMenuItem<String>(
                      child: Text("超清"),
                      value: "cq",
                    ),
                  ];
                },
                onSelected: (String action) {
                  //选择并且切换视频源
                  switch (action) {
                    case "bz":
                      setState(() {
                        videoRatioTxT = "标准";
                      });
                      changeVideoSource();
                      break;
                    case "gq":
                      setState(() {
                        videoRatioTxT = "高清";
                      });
                      break;
                    case "cq":
                      setState(() {
                        videoRatioTxT = "超清";
                      });
                      break;
                  }
                },
                onCanceled: () {
                  print("onCanceled");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

//选择完视频分辨率后更新视频源
  void changeVideoSource() async {
    var dataSource = DataSource.network(
        "https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4",
        headers: <String, String>{});
    await controller.setDataSource(dataSource, autoPlay: true);
  }

  _ProgressCalculator _calculator;

  onTap() {
    isShow = !isShow;

    if (firstbottomTimer != null) {
      firstbottomTimer.cancel();
      firstbottomTimer = null;
    }
    if (bottomBarTimer != null) {
      bottomBarTimer.cancel();
      bottomBarTimer = null;
    }
    bottomBarTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!isShow) {
        setState(() {
          isShow = true;
        });
      }
      if (bottomBarTimer != null) {
        bottomBarTimer.cancel();
        bottomBarTimer = null;
      }
    });
  }

  Function onDoubleTap() {
    return widget.doubleTapPlay
        ? () {
            controller.playOrPause();
          }
        : null;
  }

  Function wrapHorizontalGesture(Function function) =>
      widget.horizontalGesture == true ? function : null;

  Function wrapVerticalGesture(Function function) =>
      widget.verticalGesture == true ? function : null;

  void _onHorizontalDragStart(DragStartDetails details) async {
    var videoInfo = await controller.getVideoInfo();
    _calculator = _ProgressCalculator(details, videoInfo);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_calculator == null || details == null) {
      return;
    }
    var updateText = _calculator.calcUpdate(details);

    var offsetPosition = _calculator.getOffsetPosition();

    IconData iconData =
        offsetPosition > 0 ? Icons.fast_forward : Icons.fast_rewind;
    var w = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          iconData,
          color: Colors.white,
          size: 40.0,
        ),
        Text(
          updateText,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
    setState(() {
      showIconWidget = w;
    });

    //   showTooltip(createTooltipWidgetWrapper(w));
  }

  void _onHorizontalDragEnd(DragEndDetails details) async {
    setState(() {
      showIconWidget = null;
    });

    var targetSeek = _calculator?.getTargetSeek(details);
    _calculator = null;
    if (targetSeek == null) {
      return;
    }
    await controller.seekTo(targetSeek);
    var videoInfo = await controller.getVideoInfo();
    if (targetSeek < videoInfo.duration) await controller.play();
  }

  bool verticalDragging = false;
  bool leftVerticalDrag;

  void _onVerticalDragStart(DragStartDetails details) {
    //根据  横竖屏判断手势事件

    //横屏的时候执行这些逻辑
    verticalDragging = true;
    var width = UIHelper.findGlobalRect(currentKey).width;
    var dx =
        UIHelper.globalOffsetToLocal(currentKey, details.globalPosition).dx;
    leftVerticalDrag = dx / width <= 0.5;
  }

/*
 *横向滑动 
 */
  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (verticalDragging == false) return;

    String text = "";
    IconData iconData = Icons.volume_up;

    if (leftVerticalDrag == false) {
      if (details.delta.dy > 0 && details.globalPosition.dy % 2 == 0) {
        await volumeDown();
      } else if (details.delta.dy < 0 && details.globalPosition.dy % 2 == 0) {
        await volumeUp();
      }

      var currentVolume = await getVolume();

      if (currentVolume <= 0) {
        iconData = Icons.volume_mute;
      } else if (currentVolume < 50) {
        iconData = Icons.volume_down;
      } else {
        iconData = Icons.volume_up;
      }

      text = currentVolume.toString();
    } else if (leftVerticalDrag == true) {
      var currentBright = await IjkManager.getSystemBrightness();
      double target;
      if (details.delta.dy > 0) {
        target = currentBright - 0.01;
      } else {
        target = currentBright + 0.01;
      }

      if (target > 1) {
        target = 1;
      } else if (target < 0) {
        target = 0;
      }

      await IjkManager.setSystemBrightness(target);

      if (target >= 0.66) {
        iconData = Icons.brightness_high;
      } else if (target < 0.66 && target > 0.33) {
        iconData = Icons.brightness_medium;
      } else {
        iconData = Icons.brightness_low;
      }

      text = (target * 100).toStringAsFixed(0);
    } else {
      return;
    }
    var column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          iconData,
          color: Colors.white,
          size: 25.0,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
    setState(() {
      showIconWidget = column;
    });
    //   showTooltip(createTooltipWidgetWrapper(column));
  }

/*
 *横向滑动结束 
 */
  void _onVerticalDragEnd(DragEndDetails details) async {
    verticalDragging = false;
    leftVerticalDrag = null;

    setState(() {
      showIconWidget = null;
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        showIconWidget = null;
      });
    });
  }

  Future<int> getVolume() async {
    switch (widget.volumeType) {
      case VolumeType.media:
        return controller.volume;
      case VolumeType.system:
        return controller.getSystemVolume();
    }
    return 0;
  }

  Future<void> volumeUp() async {
    var volume = await getVolume();
    volume++;
    switch (widget.volumeType) {
      case VolumeType.media:
        controller.volume = volume;
        break;
      case VolumeType.system:
        await IjkManager.systemVolumeUp();
        break;
    }
  }

  Future<void> volumeDown() async {
    var volume = await getVolume();
    volume--;
    switch (widget.volumeType) {
      case VolumeType.media:
        controller.volume = volume;
        break;
      case VolumeType.system:
        await IjkManager.systemVolumeDown();
        break;
    }
  }
}

class _ProgressCalculator {
  DragStartDetails startDetails;
  VideoInfo info;

  double dx;

  _ProgressCalculator(this.startDetails, this.info);

  String calcUpdate(DragUpdateDetails details) {
    dx = details.globalPosition.dx - startDetails.globalPosition.dx;
    var f = dx > 0 ? "+" : "-";
    var offset = getOffsetPosition().round().abs();
    return "$f${offset}s";
  }

  double getTargetSeek(DragEndDetails details) {
    var target = info.currentPosition + getOffsetPosition();
    if (target < 0) {
      target = 0;
    } else if (target > info.duration) {
      target = info.duration;
    }
    return target;
  }

  double getOffsetPosition() {
    return dx / 10;
  }
}

enum VolumeType {
  system,
  media,
}

class PortraitController extends StatelessWidget {
  final IjkMediaController controller;
  final VideoInfo info;
  final TooltipDelegate tooltipDelegate;
  final bool playWillPauseOther;
  final Widget fullScreenWidget;
  final Widget playPauseWidget;
  const PortraitController({
    Key key,
    this.controller,
    this.info,
    this.tooltipDelegate,
    this.playWillPauseOther = true,
    this.fullScreenWidget,
    this.playPauseWidget,
  }) : super(key: key);

  bool get haveTime {
    return info.hasData && info.duration > 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!info.hasData) {
      return Container();
    }
    Widget bottomBar = buildBottomBar(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(),
        ),
        bottomBar,
      ],
    );
  }

  Widget buildBottomBar(BuildContext context) {
    var currentTime = buildCurrentText();
    var maxTime = buildMaxTimeText();
    var progress = buildProgress(info);

    // var playButton = buildPlayButton(context);

    var fullScreenButton = buildFullScreenButton();
    var playButton = buildPlayButton();
    Widget widget = Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      child: Row(
        children: <Widget>[
          playButton,
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: currentTime,
          ),
          Expanded(child: progress),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: maxTime,
          ),
          fullScreenButton,
        ],
      ),
    );
    widget = DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
      ),
      child: widget,
    );
    widget = Container(
      color: Colors.black.withOpacity(0.12),
      child: widget,
    );
    return widget;
  }

  Widget buildProgress(VideoInfo info) {
    if (!info.hasData || info.duration == 0) {
      return Container();
    }
    return Container(
      height: 25,
      child: ProgressBar(
        current: info.currentPosition,
        max: info.duration,
        buffered: info.bufferPosition,
        bufferColor: Colors.green[200],
        changeProgressHandler: (progress) async {
          await controller.seekToProgress(progress);
          tooltipDelegate?.hideTooltip();
        },
        tapProgressHandler: (progress) async {
          // if (controller.ijkStatus == IjkStatus.prepared ||
          //     controller.ijkStatus == IjkStatus.prepared) {
          //   controller.refreshVideoInfo();
          // }
          await controller.seekToProgress(progress);
          // tooltipDelegate?.hideTooltip();
        },
      ),
    );
  }

  buildCurrentText() {
    return haveTime
        ? Text(
            TimeHelper.getTimeText(info.currentPosition),
          )
        : Container();
  }

  buildMaxTimeText() {
    return haveTime
        ? Text(
            TimeHelper.getTimeText(info.duration),
          )
        : Container();
  }

  // buildPlayButton(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () {
  //       controller.playOrPause(pauseOther: playWillPauseOther);
  //     },
  //     child: Container(
  //       width: 25,
  //       height: 25,
  //       alignment: Alignment.center,
  //       child: Icon(
  //         info.isPlaying ? Icons.pause : Icons.play_arrow,
  //         size: 25,
  //         color: Colors.white,
  //       ),
  //     ),
  //   );
  // }

  Widget buildFullScreenButton() {
    return fullScreenWidget ?? Container();
  }

  Widget buildPlayButton() {
    return playPauseWidget ?? Container();
  }
}

abstract class TooltipDelegate {
  void showTooltip(Widget widget);

  Widget createTooltipWidgetWrapper(Widget widget);

  void hideTooltip();
}
