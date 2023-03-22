import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:zegotrial3/call_provider.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _showRemoteView = true;
  // Widget? callProvider.localView;

  late CallProvider callProvider;
  // Widget? remoteView;

  toggleRemoteView() {
    setState(() {
      _showRemoteView = !_showRemoteView;
    });
  }

  bool get showRemoteView {
    return _showRemoteView && callProvider.remoteViews.isNotEmpty;
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
      appBar: AppBar(title: const Text("Call Page")),
      body: Stack(
        children: [
          if (callProvider.fullScreenView != null)
            ZegoLocalUserUI(userView: callProvider.fullScreenView!),
          Positioned(
            top: 10,
            left: 5,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: MediaQuery.of(context).size.width - 15,
                  height: showRemoteView ? height : 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0;
                            i < callProvider.floatingViews.length;
                            i++)
                          ZegoRemoteUserUI(
                              userView: callProvider.floatingViews[i])
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: InkWell(
                      onTap: toggleRemoteView,
                      child: Container(
                        color: Colors.white30,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                        child: Icon(
                          showRemoteView
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          ZegoCallButtons()
        ],
      ),
    );
  }
}

class ZegoLocalUserUI extends StatelessWidget {
  UserView userView;
  ZegoLocalUserUI({super.key, required this.userView});
  late CallProvider callProvider;

  bool get showView => userView.isVideoOn || userView.isScreenShare;

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
      ),
      child: showView
          ? userView.view
          : SizedBox(
              child: Center(
                child: CircleAvatar(
                  radius: 120,
                  child: Text(
                    userView.iconText,
                    style: const TextStyle(fontSize: 150),
                  ),
                ),
              ),
            ),
    );
  }
}

class ZegoRemoteUserUI extends StatelessWidget {
  UserView userView;
  ZegoRemoteUserUI({super.key, required this.userView});
  late CallProvider callProvider;

  setActiveUser(UserView user) {
    callProvider.setActiveUser(user);
  }

  bool get showView => userView.isVideoOn || userView.isScreenShare;

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () => setActiveUser(userView),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withAlpha(50),
                offset: Offset(0.0, 1.0), //(x,y)
                blurRadius: 6.0,
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width / 3,
          child: AspectRatio(
            aspectRatio: 9.0 / 16.0,
            child: Stack(
              children: [
                showView
                    ? userView.view
                    : SizedBox(
                        child: Center(
                          child: CircleAvatar(
                            radius: 60,
                            child: Text(
                              userView.iconText,
                              style: const TextStyle(fontSize: 75),
                            ),
                          ),
                        ),
                      ),
                Text(userView.user.userName),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZegoCallButtons extends StatefulWidget {
  ZegoCallButtons({super.key});

  @override
  State<ZegoCallButtons> createState() => _ZegoCallButtonsState();
}

class _ZegoCallButtonsState extends State<ZegoCallButtons> {
  late CallProvider callProvider;

  UserView? get localUser {
    return callProvider.localUser;
  }

  leaveCall() async {
    // needed to call
    final navigator = Navigator.of(context);
    // await callProvider.leaveCall();
    callProvider.stopListenEvent();
    callProvider.logoutRoom();

    callProvider.stopListenEvent();
    navigator.pop();
  }

  toggleVideo() {
    callProvider.toggleVideo();
  }

  toggleAudio() {
    callProvider.toggleAudio();
  }

  toggleScreenShare() {
    callProvider.toggleScreenShare();
  }

  bool get isVideoOn => localUser!.isVideoOn;
  bool get isAudioOn => localUser!.isAudioOn;
  bool get isScreenShare => localUser!.isScreenShare;

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
                  shape: const CircleBorder(), backgroundColor: Colors.red),
              onPressed: leaveCall,
              child: const Center(child: Icon(Icons.call_end, size: 32)),
            ),
            if (localUser != null) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: isVideoOn ? Colors.blue[900] : Colors.red),
                onPressed: toggleVideo,
                child: Center(
                  child: Icon(
                    isVideoOn
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    size: 32,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: isAudioOn ? Colors.blue[900] : Colors.red),
                onPressed: toggleAudio,
                child: Center(
                  child: Icon(
                    isAudioOn ? Icons.mic_outlined : Icons.mic_off_outlined,
                    size: 32,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor:
                        isScreenShare ? Colors.blue[900] : Colors.red),
                onPressed: toggleScreenShare,
                child: Center(
                  child: Icon(
                    isScreenShare
                        ? Icons.screen_share_outlined
                        : Icons.stop_screen_share_outlined,
                    size: 32,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
