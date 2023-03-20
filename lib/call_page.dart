import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zegotrial3/call_provider.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
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

  @override
  Widget build(BuildContext context) {
    callProvider = Provider.of<CallProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Call Page")),
      body: Stack(
        children: [
          callProvider.localView ?? Container(),
          Positioned(
            top: MediaQuery.of(context).size.height / 20,
            right: MediaQuery.of(context).size.width / 20,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: AspectRatio(
                aspectRatio: 9.0 / 16.0,
                child: callProvider.remoteView ??
                    Container(color: Colors.transparent),
              ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
