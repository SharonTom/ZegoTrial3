import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zegotrial3/call_provider.dart';

import 'call_page.dart';

class CallPreviewPage extends StatefulWidget {
  const CallPreviewPage({super.key});

  @override
  State<CallPreviewPage> createState() => _CallPreviewPageState();
}

class _CallPreviewPageState extends State<CallPreviewPage> {
  late CallProvider callProvider;

  bool get showControls {
    return callProvider.showControls && callProvider.remoteViews.isNotEmpty;
  }

  double get height {
    return 16 / 9 * MediaQuery.of(context).size.width / 3;
  }

  UserView? get localUser {
    return callProvider.localUser;
  }

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Call Preview Page")),
      body: Stack(
        children: [
          if (callProvider.fullScreenView != null) ZegoLocalUserUIPreview(),
          ZegoCallPreviewButtons()
        ],
      ),
    );
  }
}

class ZegoLocalUserUIPreview extends StatefulWidget {
  ZegoLocalUserUIPreview({
    super.key,
  });

  @override
  State<ZegoLocalUserUIPreview> createState() => _ZegoLocalUserUIPreviewState();
}

class _ZegoLocalUserUIPreviewState extends State<ZegoLocalUserUIPreview>
    with AfterLayoutMixin {
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    initializeCamera();
  }

  initializeCamera() async {
    await [Permission.microphone, Permission.camera].request();

    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      enableAudio: callProvider.isAudioOn,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
  }

  CameraController? cameraController;
  List<CameraDescription> _cameras = <CameraDescription>[];

  late CallProvider callProvider;

  bool get showView => callProvider.isVideoOn && cameraController != null;

  toggleControls() {
    callProvider.toggleControls();
  }

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return InkWell(
      onTap: toggleControls,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
        ),
        child: showView
            ? CameraPreview(cameraController!)
            : const SizedBox(
                child: Center(
                  child: CircleAvatar(
                    radius: 120,
                    child: Text(
                      'S',
                      style: const TextStyle(fontSize: 150),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class ZegoCallPreviewButtons extends StatefulWidget {
  ZegoCallPreviewButtons({super.key});

  @override
  State<ZegoCallPreviewButtons> createState() => _ZegoCallPreviewButtonsState();
}

class _ZegoCallPreviewButtonsState extends State<ZegoCallPreviewButtons> {
  late CallProvider callProvider;

  UserView? get localUser {
    return callProvider.localUser;
  }

  bool get isVideoOnPreview {
    return callProvider.isVideoOn;
  }

  bool get isAudioOnPreview {
    return callProvider.isAudioOn;
  }

  joinCall() async {
    await [Permission.microphone, Permission.camera]
        .request()
        .then((value) async {
      await callProvider.initZegoCloud(context);
    });
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallPage()));
    callProvider.loginRoom();
  }

  toggleVideo() {
    callProvider.toggleVideoPreview();
  }

  toggleAudio() {
    callProvider.toggleAudioPreview();
  }

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.002,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: SizedBox(
        // width: MediaQuery.of(context).size.width / 3,
        height: MediaQuery.of(context).size.width / 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.blue.shade900),
              onPressed: joinCall,
              child: const Center(child: Icon(Icons.call, size: 32)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor:
                      isVideoOnPreview ? Colors.blue[900] : Colors.red),
              onPressed: toggleVideo,
              child: Center(
                child: Icon(
                  isVideoOnPreview
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                  size: 32,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor:
                      isAudioOnPreview ? Colors.blue[900] : Colors.red),
              onPressed: toggleAudio,
              child: Center(
                child: Icon(
                  isAudioOnPreview
                      ? Icons.mic_outlined
                      : Icons.mic_off_outlined,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
