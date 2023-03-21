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

  leaveCall() async {
    // needed to call
    final navigator = Navigator.of(context);
    // await callProvider.leaveCall();
    callProvider.stopListenEvent();
    callProvider.logoutRoom();

    callProvider.stopListenEvent();
    navigator.pop();
  }

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

  setActiveUser(UserView user) {
    callProvider.setActiveUser(user);
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

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Call Page")),
      body: Stack(
        children: [
          callProvider.fullScreenView?.view ?? Container(),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () =>
                                  setActiveUser(callProvider.floatingViews[i]),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                width: MediaQuery.of(context).size.width / 3,
                                child: AspectRatio(
                                  aspectRatio: 9.0 / 16.0,
                                  child: Stack(
                                    children: [
                                      callProvider.floatingViews[i].view,
                                      Text(callProvider
                                          .floatingViews[i].user.userName),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
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
          Positioned(
            bottom: MediaQuery.of(context).size.height / 20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.width / 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.red),
                    onPressed: leaveCall,
                    child: const Center(child: Icon(Icons.call_end, size: 32)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: Colors.red),
                    onPressed: toggleVideo,
                    child: Center(
                        child: Icon(
                      localUser != null && localUser!.isVideoOn
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                      size: 32,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
