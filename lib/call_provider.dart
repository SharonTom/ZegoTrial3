import 'dart:convert';
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
  bool isHost;
  ZegoUser user;

  UserView({
    required this.id,
    required this.view,
    required this.user,
    this.name = 'User',
    this.isAudioOn = true,
    this.isVideoOn = false,
    this.isScreenShare = false,
    this.isHost = false,
  });

  String get iconText => user.userName.characters.first;

  ExtraInfo get extraInfo => ExtraInfo(
        isAudioOn: isAudioOn,
        isVideoOn: isVideoOn,
        isScreenShare: isScreenShare,
        isHost: isHost,
      );

  static decodeExtraInfo(String _extraInfo) {
    return ExtraInfo.fromJson(_extraInfo);
  }
}

class ExtraInfo {
  bool isAudioOn;
  bool isVideoOn;
  bool isScreenShare;
  bool isHost;
  bool isRequestDisconnecting;

  ExtraInfo({
    required this.isAudioOn,
    required this.isVideoOn,
    required this.isScreenShare,
    this.isHost = false,
    this.isRequestDisconnecting = false,
  });

  String get toJson {
    return jsonEncode({
      'isAudioOn': isAudioOn,
      'isVideoOn': isVideoOn,
      'isScreenShare': isScreenShare,
      'isHost': isHost,
      'isRequestDisconnecting': isRequestDisconnecting,
    });
  }

  factory ExtraInfo.fromJson(String data) {
    final json = jsonDecode(data);
    return ExtraInfo(
      isAudioOn: json['isAudioOn'],
      isVideoOn: json['isVideoOn'],
      isScreenShare: json['isScreenShare'],
      isHost: json['isHost'] ?? false,
      isRequestDisconnecting: json['isRequestDisconnecting'] ?? false,
    );
  }
}

class CallProvider extends ChangeNotifier {
  bool localUserJoined = false;
  bool initialized = false;
  bool leftChannel = true;
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isFrontCamera = true;
  bool isScreenShared = false;
  bool isHost = false;
  String? token;
  int? uid;

  // Zego
  String? zegoToken;
  UserView? localUser;
  UserView? _activeViewFullScreen;
  List<UserView> remoteViews = [];

  String? roomId = 'Room-ID';
  int? localUserId = 741852964;

  bool showControls = true;

  toggleIsHost() {
    isHost = !isHost;
    notifyListeners();
  }

  toggleControls() {
    showControls = !showControls;
    notifyListeners();
  }

  initZegoCloud(BuildContext context) {
    ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
      1155041231,
      ZegoScenario.Default,
    ));
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

  Future<void> startPreview(ZegoUser user) async {
    late int id;
    final canvas = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      id = viewID;
      ZegoCanvas previewCanvas =
          ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    });
    if (canvas != null) {
      localUser = UserView(
        id: id,
        view: canvas,
        user: user,
        isVideoOn: isVideoOn,
        isScreenShare: isScreenShared,
        isAudioOn: isAudioOn,
        isHost: isHost,
      );
      _activeViewFullScreen = localUser;
    }
    notifyListeners();
  }

  void stopPreview() {
    ZegoExpressEngine.instance.stopPreview();
    localUser = null;
  }

  void startPlayStream(ZegoStream stream) {
    // Start to play streams. Set the view for rendering the remote streams.
    late int id;
    ZegoExpressEngine.instance.createCanvasView((viewID) {
      id = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance
          .startPlayingStream(stream.streamID, canvas: canvas);
    }).then((canvasViewWidget) {
      if (canvasViewWidget != null) {
        final extraInfo = ExtraInfo.fromJson(stream.extraInfo);
        remoteViews.add(
          UserView(
            id: id,
            view: canvasViewWidget,
            user: stream.user,
            isAudioOn: extraInfo.isAudioOn,
            isVideoOn: extraInfo.isVideoOn,
            isScreenShare: extraInfo.isScreenShare,
            isHost: extraInfo.isHost,
          ),
        );
        notifyListeners();
      }
    });
  }

  updateStream(ZegoStream stream) {
    try {
      final view = remoteViews
          .firstWhere((element) => element.user.userID == stream.user.userID);
      final extraInfo = ExtraInfo.fromJson(stream.extraInfo);
      view.isAudioOn = extraInfo.isAudioOn;
      view.isVideoOn = extraInfo.isVideoOn;
      view.isScreenShare = extraInfo.isScreenShare;
      if (extraInfo.isRequestDisconnecting) {
        stopPlayStream(stream);
      }
      if (extraInfo.isScreenShare) {
        setActiveUser(view);
      }
    } catch (e) {
      // view not found
    }
    notifyListeners();
  }

  void stopPlayStream(ZegoStream stream) {
    ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
    try {
      final view = remoteViews
          .firstWhere((element) => element.user.userID == stream.user.userID);

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
    startListenEvent();
    // The value of `userID` is generated locally and must be globally unique.
    final user = ZegoUser('$localUserId', 'User 1');

    // The value of `roomID` is generated locally and must be globally unique.
    // final roomID = widget.roomID;

    // onRoomUserUpdate callback can be received when "isUserStatusNotify" parameter value is "true".
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;
    zegoToken =
        '04AAAAAGQdxkYAEGl4c3N5dWlybWQyM2V6c3AAsORfulVMbwNGaUSEOOy5W2INCux6BSUuWMMiZS199tygVNKJ//wTg6NY48JWPNB6GWkMI47XlYaNmVAOoXK0ZHOP7hK3CvV/AXHftW/BsfQr82yAVPdrZMJib6zToO1XZIBOUSIfjESF1BP946FYn0AckO9egzIgQnBPs1egS/c3H+MhKVjRmy5HFjNf6en7qc1O4e7v6zn91/usrwEpKk1arU1c+hod9ftYidg189zZ';
    // if (kIsWeb) {
    roomConfig.token = zegoToken!;

    // log in to a room
    // Users must log in to the same room to call each other.
    ZegoExpressEngine.instance
        .loginRoom('$roomId', user, config: roomConfig)
        .then((ZegoRoomLoginResult loginRoomResult) async {
      debugPrint(
          'loginRoom: errorCode:${loginRoomResult.errorCode}, extendedData:${loginRoomResult.extendedData}');
      if (loginRoomResult.errorCode == 0) {
        await startPreview(user); // local view
        startPublish(); // send local user to remote
        localUserJoined = true;
      } else {
        // Login room failed
      }
    });
  }

  void logoutRoom() {
    final extraInfo = localUser!.extraInfo;
    extraInfo.isRequestDisconnecting = true;
    ZegoExpressEngine.instance.setStreamExtraInfo(extraInfo.toJson);
    // extrainfo
    localUser = null;
    remoteViews = [];
    ZegoExpressEngine.instance.logoutRoom();
  }

  void startPublish() {
    // After calling the `loginRoom` method, call this method to publish streams.
    // The StreamID must be unique in the room.
    String streamID = '${roomId}_${Random().nextInt(1500)}_call_1';
    setVideoAndAudioState();
    ZegoExpressEngine.instance.setStreamExtraInfo(localUser!.extraInfo.toJson);
    ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  void stopPublish() {
    ZegoExpressEngine.instance.setStreamExtraInfo(localUser!.extraInfo.toJson);
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
          debugPrint('streaminfo: ${stream.extraInfo}');
          startPlayStream(stream);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream);
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

    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = (roomID, streamList) {
      for (final stream in streamList) {
        updateStream(stream);
        debugPrint('streaminfo: ${stream.extraInfo}');
        // startPlayStream(stream.streamID, stream.user);
        debugPrint(
            'onRoomStreamExtraInfoUpdate: roomID: $roomID, extrainfo: ${stream.extraInfo}');
      }
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onRoomStreamExtraInfoUpdate = null;
    // Zegoexengi
    // ZegoExpressEngine.onuser
  }

  toggleVideo() {
    if (localUser != null && localUser!.isVideoOn) {
      // ZegoExpressEngine.instance.mutePublishStreamVideo(true);
      ZegoExpressEngine.instance.enableCamera(false);
    } else {
      ZegoExpressEngine.instance.enableCamera(true);
      ZegoExpressEngine.instance.setVideoSource(ZegoVideoSourceType.Camera);
      localUser!.isScreenShare = false;
      // ZegoExpressEngine.instance.mutePublishStreamVideo(false);
    }
    localUser!.isVideoOn = !localUser!.isVideoOn;
    ZegoExpressEngine.instance.setStreamExtraInfo(localUser!.extraInfo.toJson);
    notifyListeners();
  }

  toggleCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
    notifyListeners();
  }

  toggleAudio() {
    if (localUser != null && localUser!.isAudioOn) {
      // ZegoExpressEngine.instance.muteMicrophone(true);
      ZegoExpressEngine.instance.enableAudioCaptureDevice(false);
    } else {
      // ZegoExpressEngine.instance.muteMicrophone(false);
      ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
    }
    localUser!.isAudioOn = !localUser!.isAudioOn;
    ZegoExpressEngine.instance.setStreamExtraInfo(localUser!.extraInfo.toJson);
    notifyListeners();
  }

  toggleScreenShare() async {
    ZegoScreenCaptureSource? source =
        await ZegoExpressEngine.instance.createScreenCaptureSource();
    if (localUser == null) {
      return;
    }
    if (localUser!.isScreenShare) {
      ZegoExpressEngine.instance.setVideoSource(ZegoVideoSourceType.Camera);
      source?.stopCapture();

      setVideoAndAudioState();
    } else {
      await source?.startCapture();
      // ZegoExpressEngine.instance.mutePublishStreamVideo(false);
      await ZegoExpressEngine.instance
          .setVideoSource(ZegoVideoSourceType.ScreenCapture);

      ZegoExpressEngine.instance.enableCamera(true);
    }
    localUser!.isScreenShare = !localUser!.isScreenShare;
    ZegoExpressEngine.instance.setStreamExtraInfo(localUser!.extraInfo.toJson);
    notifyListeners();
  }

  setVideoAndAudioState() {
    if (localUser == null) {
      return;
    }
    ZegoExpressEngine.instance.enableCamera(localUser?.isVideoOn ?? false);

    ZegoExpressEngine.instance
        .enableAudioCaptureDevice(localUser?.isAudioOn ?? false);
  }
}
