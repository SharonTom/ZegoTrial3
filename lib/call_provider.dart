import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class UserView {
  int id;
  Widget view;
  String name;
  bool isAudioOn;
  bool isVideoOn;
  bool isScreenShare;
  ZegoUser user;

  UserView({
    required this.id,
    required this.view,
    required this.user,
    this.name = 'User',
    this.isAudioOn = true,
    this.isVideoOn = false,
    this.isScreenShare = false,
  });
}

class CallProvider extends ChangeNotifier {
  bool localUserJoined = false;
  bool initialized = false;
  bool leftChannel = true;
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isScreenShared = false;
  bool isPublisher = false;
  String? token;
  int? uid;

  // Zego
  String? zegoToken;
  UserView? localUser;
  UserView? _activeViewFullScreen;
  List<UserView> remoteViews = [];

  String? roomId = 'Room-ID';
  int? localUserId = 741852963;

  initZegoCloud(BuildContext context) {
    ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
      1155041231,
      ZegoScenario.Default,
    ));
    startListenEvent();
    initialized = true;
    notifyListeners();
  }

  UserView? get fullScreenView {
    return _activeViewFullScreen;
  }

  List<UserView> get floatingViews {
    if (_activeViewFullScreen?.id == localUser?.id) {
      return remoteViews;
    }
    final views = remoteViews
        .where((value) => value.id != _activeViewFullScreen?.id)
        .toList();
    return [
      if (localUser != null) localUser!,
      ...views,
    ];
  }

  setActiveUser(UserView user) {
    _activeViewFullScreen = user;
    notifyListeners();
  }

  void startPreview(ZegoUser user) {
    late int id;
    ZegoExpressEngine.instance.createCanvasView((viewID) {
      id = viewID;
      ZegoCanvas previewCanvas =
          ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    }).then((canvasViewWidget) {
      if (canvasViewWidget != null) {
        localUser = UserView(
          id: id,
          view: canvasViewWidget,
          user: user,
          isVideoOn: isVideoOn,
          isScreenShare: isScreenShared,
          isAudioOn: isAudioOn,
        );
        _activeViewFullScreen = localUser;
      }
      notifyListeners();
    });
  }

  void stopPreview() {
    ZegoExpressEngine.instance.stopPreview();
    localUser = null;
  }

  void startPlayStream(String streamID, ZegoUser user) {
    // Start to play streams. Set the view for rendering the remote streams.
    late int id;
    ZegoExpressEngine.instance.createCanvasView((viewID) {
      id = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((canvasViewWidget) {
      if (canvasViewWidget != null) {
        remoteViews.add(UserView(id: id, view: canvasViewWidget, user: user));
        notifyListeners();
      }
    });
  }

  void stopPlayStream(String streamID, ZegoUser user) {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    try {
      final view = remoteViews
          .firstWhere((element) => element.user.userID == user.userID);

      ZegoExpressEngine.instance.destroyCanvasView(view.id);
      remoteViews.remove(view);
      if (view.id == _activeViewFullScreen?.id) {
        _activeViewFullScreen = localUser;
      }
      notifyListeners();
    } catch (e) {
      print('user remove failed');
    }
  }

  void loginRoom() {
    // The value of `userID` is generated locally and must be globally unique.
    final user = ZegoUser('$localUserId', 'User 1');

    // The value of `roomID` is generated locally and must be globally unique.
    // final roomID = widget.roomID;

    // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;
    zegoToken =
        '04AAAAAGQbJEYAEGkzcnprZTkybjBkZnNlMGUAsPIopAZXduBosWhAwDhvm5eiw6e3vBYKY9nOX0uXwv/b7hiTtVsF5TiKmEp8vy/srhsuOQwX4EtMcqcwZO1KbGb7J+Sf65lppMHwzmDC0fD9b+z1lqNE75+Hz4RSC/DmdOCiyQtm5nXgyV+cDE27teH31Zd9dgmsPEA/215TXoGmw+qvfbJPxUb4qRMQUGUm1MT/xSn0oRQ/QL2YaSluPEma0/gZdMlI/3bFkTOpxgO9';
    // if (kIsWeb) {
    roomConfig.token = zegoToken!;

    // log in to a room
    // Users must log in to the same room to call each other.
    ZegoExpressEngine.instance
        .loginRoom('$roomId', user, config: roomConfig)
        .then((ZegoRoomLoginResult loginRoomResult) {
      debugPrint(
          'loginRoom: errorCode:${loginRoomResult.errorCode}, extendedData:${loginRoomResult.extendedData}');
      if (loginRoomResult.errorCode == 0) {
        startPreview(user); // local view
        startPublish(); // send local user to remote
        localUserJoined = true;
      } else {
        // Login room failed
      }
    });
  }

  void logoutRoom() {
    localUser = null;
    remoteViews = [];
    ZegoExpressEngine.instance.logoutRoom();
  }

  void startPublish() {
    // After calling the `loginRoom` method, call this method to publish streams.
    // The StreamID must be unique in the room.
    String streamID = '${roomId}_${Random().nextInt(1500)}_call_1';
    ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  void stopPublish() {
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  void startListenEvent() {
    // Callback for updates on the status of other users in the room.
    // Users can only receive callbacks when the isUserStatusNotify property of ZegoRoomConfig is set to `true` when logging in to the room (loginRoom).
    ZegoExpressEngine.onRoomUserUpdate =
        (roomID, updateType, List<ZegoUser> userList) {
      debugPrint(
          'onRoomUserUpdate: roomID: $roomID, updateType: ${updateType.name}, userList: ${userList.map((e) => e.userID)}');
    };
    // Callback for updates on the status of the streams in the room.
    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, List<ZegoStream> streamList, extendedData) {
      debugPrint(
          'onRoomStreamUpdate: roomID: $roomID, updateType: $updateType, streamList: ${streamList.map((e) => e.streamID)}, extendedData: $extendedData');
      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          startPlayStream(stream.streamID, stream.user);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID, stream.user);
        }
      }
    };
    // Callback for updates on the current user's room connection status.
    ZegoExpressEngine.onRoomStateUpdate =
        (roomID, state, errorCode, extendedData) {
      debugPrint(
          'onRoomStateUpdate: roomID: $roomID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };

    // Callback for updates on the current user's stream publishing changes.
    ZegoExpressEngine.onPublisherStateUpdate =
        (streamID, state, errorCode, extendedData) {
      debugPrint(
          'onPublisherStateUpdate: streamID: $streamID, state: ${state.name}, errorCode: $errorCode, extendedData: $extendedData');
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }

  toggleVideo() {
    final user = ZegoUser('$localUserId', 'User 1');
    if (localUser != null && localUser!.isVideoOn) {
      ZegoExpressEngine.instance.mutePublishStreamVideo(true);
    } else {
      ZegoExpressEngine.instance.mutePublishStreamVideo(false);
    }
    localUser?.isVideoOn = !localUser!.isVideoOn;
    notifyListeners();
  }

  toggleAudio() {
    final user = ZegoUser('$localUserId', 'User 1');
    if (localUser != null && localUser!.isAudioOn) {
      ZegoExpressEngine.instance.muteMicrophone(true);
    } else {
      ZegoExpressEngine.instance.muteMicrophone(false);
    }
    localUser?.isAudioOn = !localUser!.isAudioOn;
    notifyListeners();
  }

  toggleScreenShare() async {
    final user = ZegoUser('$localUserId', 'User 1');
    ZegoScreenCaptureSource? source =
        await ZegoExpressEngine.instance.createScreenCaptureSource();
    if (localUser != null && localUser!.isScreenShare) {
      ZegoExpressEngine.instance
          .setVideoSource(ZegoVideoSourceType.ScreenCapture);

      ZegoExpressEngine.instance.mutePublishStreamVideo(false);
      source?.startCapture();
    } else {
      source?.stopCapture();
      ZegoExpressEngine.instance.setVideoSource(ZegoVideoSourceType.Camera);
      if (localUser != null && localUser!.isVideoOn) {
        ZegoExpressEngine.instance.mutePublishStreamVideo(false);
      } else {
        ZegoExpressEngine.instance.mutePublishStreamVideo(true);
      }
    }
    localUser?.isScreenShare = !localUser!.isScreenShare;
    notifyListeners();
  }
}
