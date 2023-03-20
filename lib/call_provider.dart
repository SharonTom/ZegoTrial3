import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

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
  int? localViewID;
  Widget? localView;
  int? remoteViewID;
  Widget? remoteView;

  String? roomId = 'Room-ID';
  int? localUserId = 741852964;

  initZegoCloud(BuildContext context) {
    ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
      1155041231,
      ZegoScenario.Default,
    ));
    startListenEvent();
    initialized = true;
    notifyListeners();
  }

  void startPreview() {
    ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
      ZegoCanvas previewCanvas =
          ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas);
    }).then((canvasViewWidget) {
      localView = canvasViewWidget;
      notifyListeners();
    });
  }

  void stopPreview() {
    ZegoExpressEngine.instance.stopPreview();
    localView = null;
    localViewID = null;
  }

  void startPlayStream(String streamID) {
// Start to play streams. Set the view for rendering the remote streams.
    ZegoExpressEngine.instance.createCanvasView((viewID) {
      remoteViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((canvasViewWidget) {
      if (canvasViewWidget != null) {
        remoteView = canvasViewWidget;
        notifyListeners();
      }
    });
  }

  void stopPlayStream(String streamID) {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    ZegoExpressEngine.instance.destroyCanvasView(remoteViewID!);
    remoteView = null;
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
        '04AAAAAGQZxZ0AEHJrd3pnZjJlMDdkM3ZybDkAsGFP1N+wJt/fPPyx6sp0cGIlTF6qAgGwv9u1NJxaav1wOVcs+gGoIU0krl2Ov1IwdY4u6kqHTrk71c6W+Kas5PuVfv9cA1ECOamnIaOp3dMNGFek9XB6qs8jj8yu6rwABOED4gj40+ij7X9yQ3w1oWzrNYSb+JnCLg8tzD3x04iETWj8m9yJWvTDpLutrUEMhAhAMooUDYDGFNxyEDI4AzEqFhWSsH5gOTTBu6R5/cII';
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
        startPreview(); // local view
        startPublish(); // send local user to remote
        localUserJoined = true;
      } else {
        // Login room failed
      }
    });
  }

  void logoutRoom() {
    localView = null;
    remoteView = null;
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
          startPlayStream(stream.streamID);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID);
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
}
