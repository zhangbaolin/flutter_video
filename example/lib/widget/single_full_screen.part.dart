part of './single_controller_build.dart';

enum FullScreenType {
  rotateScreen,
  rotateBox,
}

showFullScreenIJKPlayer(
  BuildContext context,
  IjkMediaController controller, {
  IJKControllerWidgetBuilder fullscreenControllerWidgetBuilder,
  FullScreenType fullScreenType = FullScreenType.rotateBox,
}) async {
  if (fullScreenType == FullScreenType.rotateBox) {
    _showFullScreenWithRotateBox(
      context,
      controller,
      fullscreenControllerWidgetBuilder: fullscreenControllerWidgetBuilder,
    );
    return;
  }
}



_showFullScreenWithRotateBox(
  BuildContext context,
  IjkMediaController controller, {
  IJKControllerWidgetBuilder fullscreenControllerWidgetBuilder,
}) async {
  var info = await controller.getVideoInfo();

  if(info.width!=null&&info.height!=null){
       Axis axis;

  if (info.width == 0 || info.height == 0) {
    axis = Axis.horizontal;
  } else if (info.width > info.height) {
    if (info.degree == 90 || info.degree == 270) {
      axis = Axis.vertical;
    } else {
      axis = Axis.horizontal;
    }
  } else {
    if (info.degree == 90 || info.degree == 270) {
      axis = Axis.horizontal;
    } else {
      axis = Axis.vertical;
    }
  }

  Navigator.push(
    context,
    FullScreenRoute(
      builder: (ctx) {
        var mediaQueryData = MediaQuery.of(ctx);

        int quarterTurns;

        if (axis == Axis.horizontal) {
          if (mediaQueryData.orientation == Orientation.landscape) {
            quarterTurns = 0;
          } else {
            quarterTurns = 1;
          }
        } else {
          quarterTurns = 0;
        }
        /*else {
          if (mediaQueryData.orientation == Orientation.portrait) {
            quarterTurns = 0;
          } else {
            quarterTurns = -1;
          }
        }*/
  
        return SafeArea(
          child: RotatedBox(
            quarterTurns: quarterTurns,
            child: IjkPlayer(
              mediaController: controller,
              controllerWidgetBuilder: (ctl) =>
                  fullscreenControllerWidgetBuilder(ctl),
            ),
          ),
        );
      },
    ),
  );
  }
}

Widget _buildFullScreenMediaController(
    IjkMediaController controller, bool fullScreen) {
  return DefaultIJKControllerWidget (
    controller: controller,
    currentFullScreenState: true,
  );
}

Widget buildFullscreenMediaController(IjkMediaController controller) {
  return _buildFullScreenMediaController(controller, true);
}
