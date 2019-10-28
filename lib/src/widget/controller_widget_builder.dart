import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:flutter_video/src/helper/full_screen_helper.dart';
import 'package:flutter_video/src/helper/logutil.dart';
import 'package:flutter_video/src/helper/time_helper.dart';
import 'package:flutter_video/src/helper/ui_helper.dart';
import 'package:flutter_video/src/route/fullscreen_route.dart';
import 'package:flutter_video/src/widget/progress_bar.dart';
import 'package:orientation/orientation.dart';
import 'package:screen/screen.dart';

part 'full_screen.part.dart';

/// Using mediaController to Construct a Controller UI
typedef Widget IJKControllerWidgetBuilder(IjkMediaController controller);

/// default create IJK Controller UI
Widget defaultBuildIjkControllerWidget(IjkMediaController controller) {
  return DefaultIJKControllerWidget(
    controller: controller,
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

  /// The UI of the controller.
  const DefaultIJKControllerWidget({
    Key key,
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
  }) : super(key: key);

  @override
  _DefaultIJKControllerWidgetState createState() =>
      _DefaultIJKControllerWidgetState();

  DefaultIJKControllerWidget copyWith({
    Key key,
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
  }) {
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
    );
  }
}

class _DefaultIJKControllerWidgetState extends State<DefaultIJKControllerWidget>
    with TickerProviderStateMixin
    implements TooltipDelegate {
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
//新添加计时器
  Timer bottomBarTimer;
  Timer firstbottomTimer;
  //新添加属性
  bool isVoiceNone = false;
  bool isShowad = false; //是否显示广告
  bool isSeeselectredou = true;

  // //添加广告动画
  // //动画控制器
  // AnimationController animationController;
  // Animation<Offset> animation;
  var value;
  @override
  void initState() {
    super.initState();
    startTimer();
    controllerSubscription =
        controller.textureIdStream.listen(_onTextureIdChange);
    isShowbottomBar();
    //保持屏幕常亮
    Screen.keepOn(true);
    //adAnimation();
  }

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
    // LogUtils.debug("onTextureChange $textureId");
    if (textureId != null) {
      startTimer();
    } else {
      stopTimer();
    }
  }

//   adAnimation() {
//     animationController =
//         AnimationController(duration: const Duration(seconds: 2), vsync: this);
//     //动画开始、结束、向前移动或向后移动时会调用StatusListener

//     animation = Tween(begin: Offset(-1, 0), end: Offset(0, 0))
//         .animate(animationController);

// //开始执行动画
//     animationController.forward();
//   }

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

    // if (animationController != null) {
    //   animationController.dispose();
    // }
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
    });
  }

  void stopTimer() {
    progressTimer?.cancel();
    progressTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    // if (controller.isNomal) {
    //   //
    //   return GestureDetector(
    //     behavior: HitTestBehavior.opaque,
    //     child: buildContent(),
    //     onDoubleTap: onDoubleTap(),
    //     onHorizontalDragStart: wrapHorizontalGesture(_onHorizontalDragStart),
    //     onHorizontalDragUpdate: wrapHorizontalGesture(_onHorizontalDragUpdate),
    //     onHorizontalDragEnd: wrapHorizontalGesture(_onHorizontalDragEnd),
    //     onVerticalDragStart: wrapVerticalGesture(_onVerticalDragStart),
    //     onVerticalDragUpdate: wrapVerticalGesture(_onVerticalDragUpdate),
    //     onVerticalDragEnd: wrapVerticalGesture(_onVerticalDragEnd),
    //     onTap: onTap,
    //     key: currentKey,
    //   );
    // } else {
    //   //列表的视频
    //   return GestureDetector(
    //     behavior: HitTestBehavior.opaque,
    //     child: buildContent(),
    //     onDoubleTap: onDoubleTap(),
    //     onHorizontalDragStart: wrapHorizontalGesture(_onHorizontalDragStart),
    //     onHorizontalDragUpdate: wrapHorizontalGesture(_onHorizontalDragUpdate),
    //     onHorizontalDragEnd: wrapHorizontalGesture(_onHorizontalDragEnd),
    //     onTap: onTap,
    //     key: currentKey,
    //   );
    // }
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
  }

  Widget buildContent() {
    // if (!isShow) {
    //   return Container();
    // }
    // return StreamBuilder<VideoInfo>(
    //   stream: controller.videoInfoStream,
    //   builder: (context, snapshot) {
    //     var info = snapshot.data;
    //     if (info == null || !info.hasData) {
    //       return Container();
    //     }
    //     return buildPortrait(info);
    //   },
    // );

    return StreamBuilder<VideoInfo>(
      stream: controller.videoInfoStream,
      builder: (context, snapshot) {
        var info = snapshot.data;
        if (info == null || !info.hasData) {
          return Container();
        }
        return Stack(
          children: <Widget>[
            Offstage(
              offstage: isShow,
              child: buildPortrait(info),
            ),
          //  adbuild(), //广告
          ],
        );
      },
    );
  }

//广告
  // Widget adbuild() {
  //   return Align(
  //     alignment: Alignment.centerLeft,
  //     child: SlideTransition(
  //       position: animation,
  //       //将要执行动画的子view
  //       child: Stack(
  //         children: <Widget>[
  //           Container(
  //             alignment: Alignment.center,
  //             width: 150,
  //             height: 80,
  //             color: Colors.green,
  //             child: Text(
  //               "这是一个广告啊",
  //               style: TextStyle(color: Colors.white, fontSize: 15),
  //             ),
  //           ),
  //           Container(
  //             width: 150,
  //             height: 80,
  //             color: Colors.orange,
  //             alignment: Alignment.topRight,
  //             child: GestureDetector(
  //               onTap: () {
  //                 animationController.reverse();
  //               },
  //               child: Icon(Icons.delete_sweep, color: Colors.white, size: 20),
  //             ),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFullScreenButton() {
    if (widget.showFullScreenButton != true) {
      return Container();
    }
    var isFull = widget.currentFullScreenState;

    // IJKControllerWidgetBuilder fullscreenBuilder =
    //     widget.fullscreenControllerWidgetBuilder ??
    //         (ctx) => FullIJKControllerWidget(
    //               controller: controller,
    //             );

    IJKControllerWidgetBuilder fullscreenBuilder =
        widget.fullscreenControllerWidgetBuilder ??
            (ctx) => widget.copyWith(currentFullScreenState: true);

    return IconButton(
      color: Colors.white,
      icon: Icon(isFull ? Icons.fullscreen_exit : Icons.fullscreen),
      onPressed: () async {
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
      },
    );
  }

  int _overlayTurns = 0;

  Widget buildPortrait(VideoInfo info) {
    _overlayTurns = FullScreenHelper.getQuarterTurns(info, context);
    return Stack(
      children: <Widget>[
        PortraitController(
          controller: controller,
          info: info,
          tooltipDelegate: this,
          playWillPauseOther: widget.playWillPauseOther,
          fullScreenWidget: _buildFullScreenButton(),
        ),
        voiceIcon(),
        videoTitle()
      ],
    );
  }

  OverlayEntry _tipOverlay;
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
                  "标题：今天是个好日子",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
//             Container(
//               width: 60,
//               child: PopupMenuButton(
// //              icon: Icon(Icons.home),
//                 child: Text(
//                   "高清",
//                   style: TextStyle(color: Colors.white, fontSize: 12),
//                 ),
//                 tooltip: "长按提示",
//                 initialValue: "hot",
//                 padding: EdgeInsets.all(0.0),
//                 itemBuilder: (BuildContext context) {
//                   return <PopupMenuItem<String>>[
//                     PopupMenuItem<String>(
//                       child: Text("标准"),
//                       value: "bz",
//                     ),
//                     PopupMenuItem<String>(
//                       child: Text("高清"),
//                       value: "gq",
//                     ),
//                     PopupMenuItem<String>(
//                       child: Text("超清"),
//                       value: "cq",
//                     ),
//                   ];
//                 },
//                 onSelected: (String action) {
//                   switch (action) {
//                     case "bz":
//                       print("标准");
//                       break;
//                     case "gq":
//                       print("高清");
//                       break;
//                     case "cq":
//                       print("超清");
//                       break;
//                   }
//                 },
//                 onCanceled: () {
//                   print("onCanceled");
//                 },
//               ),
//             ),
//             Container(
//               width: 60,
//               alignment: Alignment.center,
//               child: Text(
//                 "暂无",
//                 style: TextStyle(color: Colors.white, fontSize: 12),
//               ),
//             ),
          ],
        ),
      ),
    );
  }

  Widget createTooltipWidgetWrapper(Widget widget) {
    var typography = Typography(platform: TargetPlatform.android);
    var theme = typography.white;
    const style = const TextStyle(
      fontSize: 15.0,
      color: Colors.white,
      fontWeight: FontWeight.normal,
    );
    var mergedTextStyle = theme.body2.merge(style);
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.0),
      ),
      height: 100.0,
      width: 100.0,
      child: DefaultTextStyle(
        child: widget,
        style: mergedTextStyle,
      ),
    );
  }

  void showTooltip(Widget widget) {
    hideTooltip();
    _tipOverlay = OverlayEntry(
      builder: (BuildContext context) {
        Widget w = IgnorePointer(
          child: Center(
            child: widget,
          ),
        );

        if (this.widget.fullScreenType == FullScreenType.rotateBox &&
            this.widget.currentFullScreenState &&
            _overlayTurns != 0) {
          w = RotatedBox(
            child: w,
            quarterTurns: _overlayTurns,
          );
        }

        return w;
      },
    );
    Overlay.of(context).insert(_tipOverlay);
  }

  void hideTooltip() {
    _tipOverlay?.remove();

    _tipOverlay = null;
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
            LogUtils.debug("ondouble tap");
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
        ),
      ],
    );

    showTooltip(createTooltipWidgetWrapper(w));
  }

  void _onHorizontalDragEnd(DragEndDetails details) async {
    hideTooltip();
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

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (verticalDragging == false) return;

    String text = "";
    IconData iconData = Icons.volume_up;
    print('滑动的详情：${details.globalPosition.dy}');
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
          child: Text(text),
        ),
      ],
    );

    showTooltip(createTooltipWidgetWrapper(column));
  }

  void _onVerticalDragEnd(DragEndDetails details) async {
    verticalDragging = false;
    leftVerticalDrag = null;
    hideTooltip();

    Future.delayed(const Duration(milliseconds: 2000), () {
      hideTooltip();
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

class PortraitController extends StatelessWidget {
  final IjkMediaController controller;
  final VideoInfo info;
  final TooltipDelegate tooltipDelegate;
  final bool playWillPauseOther;
  final Widget fullScreenWidget;

  const PortraitController({
    Key key,
    this.controller,
    this.info,
    this.tooltipDelegate,
    this.playWillPauseOther = true,
    this.fullScreenWidget,
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

    var playButton = buildPlayButton(context);

    var fullScreenButton = buildFullScreenButton();

    Widget widget = Row(
      children: <Widget>[
        playButton,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: currentTime,
        ),
        Expanded(child: progress),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: maxTime,
        ),
        fullScreenButton,
      ],
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
          // showProgressTooltip(info, progress);
          if (controller.ijkStatus == IjkStatus.prepared ||
              controller.ijkStatus == IjkStatus.prepared) {
            controller.refreshVideoInfo();
            //  print("点击了progress，修改了视频播放的状态${controller.ijkStatus}");
          }
          await controller.seekToProgress(progress);
          tooltipDelegate?.hideTooltip();
          //   print("点击了progress，修改了视频播放的状态${controller.ijkStatus}");
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

  buildPlayButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        controller.playOrPause(pauseOther: playWillPauseOther);
      },
      color: Colors.white,
      icon: Icon(info.isPlaying ? Icons.pause : Icons.play_arrow),
      iconSize: 25.0,
    );
  }

  void showProgressTooltip(VideoInfo info, double progress) {
    var target = info.duration * progress;

    var diff = info.currentPosition - target;

    String diffString;
    if (diff < 1 && diff > -1) {
      diffString = "0s";
    } else if (diff < 0) {
      diffString = "+${TimeHelper.getTimeText(diff.abs())}";
    } else if (diff > 0) {
      diffString = "-${TimeHelper.getTimeText(diff.abs())}";
    } else {
      diffString = "0s";
    }

    Widget text = Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            TimeHelper.getTimeText(target),
            style: TextStyle(fontSize: 20),
          ),
          Container(
            height: 10,
          ),
          Text(diffString),
        ],
      ),
    );

    var tooltip = tooltipDelegate?.createTooltipWidgetWrapper(text);
    tooltipDelegate?.showTooltip(tooltip);
  }

  Widget buildFullScreenButton() {
    return fullScreenWidget ?? Container();
  }
}

abstract class TooltipDelegate {
  void showTooltip(Widget widget);

  Widget createTooltipWidgetWrapper(Widget widget);

  void hideTooltip();
}

enum VolumeType {
  system,
  media,
}
