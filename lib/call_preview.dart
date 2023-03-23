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
      backgroundColor: Colors.blueGrey[800],
      appBar: AppBar(title: const Text("Call Preview Page")),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Expanded(child: ZegoLocalUserUIPreview()),
            ZegoCallPreviewButtons(),
          ],
        ),
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
  CameraController? cameraController;
  List<CameraDescription> _cameras = <CameraDescription>[];

  late CallProvider callProvider;

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    initializeCamera();
  }

  initializeCamera() async {
    // await [Permission.microphone, Permission.camera].request();

    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras.last,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await cameraController!.initialize();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // cameraController = cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController!.description);
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = cameraController;
    if (oldController != null) {
      // `controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
      cameraController = null;
      await oldController.dispose();
    }
    initializeCamera();
  }

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
        width: MediaQuery.of(context).size.width,
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
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => CallPage()));
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
    return Container(
      // bottom: MediaQuery.of(context).size.height * 0.002,
      width: MediaQuery.of(context).size.width * 0.75,
      // right: MediaQuery.of(context).size.width * 0.1,
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
