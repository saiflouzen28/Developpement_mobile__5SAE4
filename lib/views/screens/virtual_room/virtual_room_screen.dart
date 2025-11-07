// lib/views/screens/virtual_room/virtual_room_screen.dart
import 'package:flutter/material.dart';
// Import the new, more powerful webview package
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Create an instance of our tiny local web server
final InAppLocalhostServer localhostServer = InAppLocalhostServer();

class VirtualRoomScreen3D extends StatefulWidget {
  final int roomId;
  const VirtualRoomScreen3D({super.key, required this.roomId});

  @override
  State<VirtualRoomScreen3D> createState() => _VirtualRoomScreen3DState();
}

class _VirtualRoomScreen3DState extends State<VirtualRoomScreen3D> {
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    // Start the local server when the screen is initialized
    _startServer();
  }

  // We must stop the server when the screen is closed to free up resources
  @override
  void dispose() {
    localhostServer.close();
    super.dispose();
  }

  Future<void> _startServer() async {
    // Start the server if it's not already running
    if (!localhostServer.isRunning()) {
      await localhostServer.start();
    }
    // This tells the state to rebuild now that the server is ready,
    // which will then build the InAppWebView widget.
    setState(() {});
  }

  // Helper to send move commands TO JavaScript
  void _postWebMessage(String type, double value) {
    _webViewController?.evaluateJavascript(source: 'window.postMessage({ type: "$type", value: $value })');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interactive 3D Room #${widget.roomId}'),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: Stack(
        children: [
          // Only build the WebView if the server is running
          if (localhostServer.isRunning())
            InAppWebView(
              // Load the 3d_room.html file from the local server.
              // This makes it think it's a real website.
              initialUrlRequest: URLRequest(url: WebUri('http://localhost:8080/assets/www/3d_room.html')),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onConsoleMessage: (controller, consoleMessage) {
                // This line is very useful for debugging!
                // It prints messages from the JavaScript console to your Flutter terminal.
                print("From WebView: ${consoleMessage.message}");
              },
            )
          else
            const Center(child: CircularProgressIndicator()), // Show a loader while server starts

          _buildMovementControls(),
        ],
      ),
    );
  }

  // --- UI CONTROLS (Updated for the new message format) ---
  Widget _buildMovementControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Turn Left Controls
          GestureDetector(
            onLongPressStart: (_) => _postWebMessage('turn', 1.0),
            onLongPressEnd: (_) => _postWebMessage('turn', 0.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
              child: const Icon(Icons.rotate_left, color: Colors.white),
            ),
          ),
          // Move Forward/Backward Controls
          Column(
            children: [
              GestureDetector(
                onLongPressStart: (_) => _postWebMessage('move', 1.0),
                onLongPressEnd: (_) => _postWebMessage('move', 0.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onLongPressStart: (_) => _postWebMessage('move', -1.0),
                onLongPressEnd: (_) => _postWebMessage('move', 0.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
          // Turn Right Controls
          GestureDetector(
            onLongPressStart: (_) => _postWebMessage('turn', -1.0),
            onLongPressEnd: (_) => _postWebMessage('turn', 0.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
              child: const Icon(Icons.rotate_right, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
