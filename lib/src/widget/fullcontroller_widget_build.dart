import 'dart:async';
import 'dart:io';

import 'package:flutter_video/src/widget/controller_widget_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video/flutter_video.dart';
import 'package:flutter_video/src/helper/full_screen_helper.dart';
import 'package:flutter_video/src/helper/logutil.dart';
import 'package:flutter_video/src/helper/time_helper.dart';
import 'package:flutter_video/src/helper/ui_helper.dart';
import 'package:flutter_video/src/widget/progress_bar.dart';
import 'package:orientation/orientation.dart';
import 'package:screen/screen.dart';

/// Using mediaController to Construct a Controller UI
typedef Widget IJKControllerWidgetBuilder(IjkMediaController controller);

/// default create IJK Controller UI
Widget defaultBuildIjkControllerWidget(IjkMediaController controller) {
  return FullIJKControllerWidget(
    controller: controller,
    fullscreenControllerWidgetBuilder: (ctl) =>
        buildFullscreenMediaController(ctl),
  );
}

/// Default Controller Widget
///
/// see [IjkPlayer] and [IJKControllerWidgetBuilder]
class FullIJKControllerWidget extends StatefulWidget {
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
  const FullIJKControllerWidget({
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
}

class _DefaultIJKControllerWidgetState extends State<FullIJKControllerWidget>
    implements TooltipDelegate {
  IjkMediaController get controller => widget.controller;

  GlobalKey currentKey = GlobalKey();

  bool _isShow = true;

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
  @override
  void initState() {
    super.initState();
    startTimer();
    controllerSubscription =
        controller.textureIdStream.listen(_onTextureIdChange);
    bottomBarTimer = Timer.periodic(Duration(seconds: 7), (timer) {
      if (isShow) {
        setState(() {
          isShow = !isShow;
        });
      }
    });

    //全屏状态下保持屏幕火星
    Screen.keepOn(true);
  }

  void _onTextureIdChange(int textureId) {
    // LogUtils.debug("onTextureChange $textureId");
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
   // Screen.keepOn(false);
    controllerSubscription.cancel();
    stopTimer();
    IjkManager.resetBrightness();
    // 强制竖屏
    print('播放器控制器被销毁了');
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    if (Platform.isIOS) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    }
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
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
    if (!isShow) {
      return Container();
    }
    return StreamBuilder<VideoInfo>(
      stream: controller.videoInfoStream,
      builder: (context, snapshot) {
        var info = snapshot.data;
        if (info == null || !info.hasData) {
          return Container();
        }
        return buildPortrait(info);
      },
    );
  }

  Widget _buildFullScreenButton() {
    if (widget.showFullScreenButton != true) {
      return Container();
    }
    var isFull = widget.currentFullScreenState;

    IJKControllerWidgetBuilder fullscreenBuilder =
        widget.fullscreenControllerWidgetBuilder ??
            (ctx) => defaultBuildIjkControllerWidget(controller);

    return IconButton(
      color: Colors.white,
      icon: Icon(isFull ? Icons.fullscreen_exit : Icons.fullscreen),
      onPressed: () async {
        if (isFull) {
          Navigator.pop(context);
          print('取消全屏了啊');
          // 强制竖屏
          SystemChrome.setPreferredOrientations(
              [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
          SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
          if (Platform.isIOS) {
            OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
          }
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft,
          ]);
          if (Platform.isIOS) {
            OrientationPlugin.forceOrientation(DeviceOrientation.landscapeLeft);
          }

          SystemChrome.setEnabledSystemUIOverlays([]);
          showFullScreenIJKPlayer(
            context,
            controller,
            fullscreenControllerWidgetBuilder: fullscreenBuilder,
            fullScreenType: widget.fullScreenType,
          );

          print('我要设置全屏了');
        }
      },
    );
  }

  int _overlayTurns = 0;

  Widget buildPortrait(VideoInfo info) {
    _overlayTurns = FullScreenHelper.getQuarterTurns(info, context);
    return PortraitController(
      controller: controller,
      info: info,
      tooltipDelegate: this,
      playWillPauseOther: widget.playWillPauseOther,
      fullScreenWidget: _buildFullScreenButton(),
    );
  }

  OverlayEntry _tipOverlay;

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

  onTap() => isShow = !isShow;

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
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      //横屏的时候执行这些逻辑
      verticalDragging = true;
      var width = UIHelper.findGlobalRect(currentKey).width;
      var dx =
          UIHelper.globalOffsetToLocal(currentKey, details.globalPosition).dx;
      leftVerticalDrag = dx / width <= 0.5;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
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
  }

  void _onVerticalDragEnd(DragEndDetails details) async {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      verticalDragging = false;
      leftVerticalDrag = null;
      hideTooltip();

      Future.delayed(const Duration(milliseconds: 2000), () {
        hideTooltip();
      });
    }
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
      height: 22,
      child: ProgressBar(
        current: info.currentPosition,
        max: info.duration,
        buffered: info.bufferPosition,
        bufferColor: Colors.green[200],
        changeProgressHandler: (progress) async {
          await controller.seekToProgress(progress);
          tooltipDelegate?.hideTooltip();
        },
        tapProgressHandler: (progress) {
          // showProgressTooltip(info, progress);
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
