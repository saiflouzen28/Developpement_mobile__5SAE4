import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math';// Server instance (this is correct)
final InAppLocalhostServer localhostServer = InAppLocalhostServer();

// --- VIRTUAL ROOM SCREEN ---
class VirtualRoomScreen3D extends StatefulWidget {
  final int roomId;
  const VirtualRoomScreen3D({super.key, required this.roomId});

  @override
  State<VirtualRoomScreen3D> createState() => _VirtualRoomScreen3DState();
}

class _VirtualRoomScreen3DState extends State<VirtualRoomScreen3D> {
  InAppWebViewController? _webViewController;
  PlayerState _playerState = PlayerState(x: 0, y: 0, rotation: 0);
  final double roomSize = 20.0;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    if (!localhostServer.isRunning()) {
      await localhostServer.start();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    localhostServer.close();
    super.dispose();
  }

  void _postJoystickMessage(double forward, double turn) {
    _webViewController?.evaluateJavascript(source: '''
      window.postMessage({ type: "joystick", forward: $forward, turn: $turn });
    ''');
  }

  void _postMoveToMessage(double x, double z) {
    _webViewController?.evaluateJavascript(source: '''
      window.postMessage({ type: "move-to", x: $x, z: $z });
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interactive 3D Room #${widget.roomId}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (localhostServer.isRunning())
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('http://localhost:8080/assets/www/3d_room.html')),
              onWebViewCreated: (controller) {
                _webViewController = controller;

                // --- THIS IS THE FINAL, DEFINITIVE FIX ---
                // We will use addJavaScriptHandler, which has a stable API.
                // It listens for a global function call from JavaScript.
                controller.addJavaScriptHandler(
                  handlerName: 'updatePosition', // The name of the function JS will call
                  callback: (args) {
                    // args[0] will be the map {x: ..., y: ..., rotation: ...}
                    if (args.isNotEmpty && args[0] is Map && mounted) {
                      setState(() {
                        _playerState = PlayerState.fromMap(Map<String, dynamic>.from(args[0]));
                      });
                    }
                  },
                );
                // --- END OF FIX ---
              },
              onConsoleMessage: (controller, consoleMessage) {
                print("From WebView: ${consoleMessage.message}");
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
          _buildMovementControls(),
          Positioned(
            top: 10,
            right: 10,
            child: MiniMap(
              playerState: _playerState,
              roomSize: roomSize,
              onTap: (x, z) {
                _postMoveToMessage(x, z);
              },
            ),
          ),
        ],
      ),
    );
  }

  // The rest of the file is identical and correct.
  Widget _buildMovementControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildJoystickButton(Icons.rotate_left, onLongPressStart: () => _postJoystickMessage(0, 1.0), onLongPressEnd: () => _postJoystickMessage(0, 0)),
          Column(
            children: [
              _buildJoystickButton(Icons.arrow_upward, onLongPressStart: () => _postJoystickMessage(1.0, 0), onLongPressEnd: () => _postJoystickMessage(0, 0)),
              const SizedBox(height: 10),
              _buildJoystickButton(Icons.arrow_downward, onLongPressStart: () => _postJoystickMessage(-1.0, 0), onLongPressEnd: () => _postJoystickMessage(0, 0)),
            ],
          ),
          _buildJoystickButton(Icons.rotate_right, onLongPressStart: () => _postJoystickMessage(0, -1.0), onLongPressEnd: () => _postJoystickMessage(0, 0)),
        ],
      ),
    );
  }

  Widget _buildJoystickButton(IconData icon, {required VoidCallback onLongPressStart, required VoidCallback onLongPressEnd}) {
    return GestureDetector(
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

class PlayerState {
  final double x;
  final double y;
  final double rotation;

  PlayerState({required this.x, required this.y, required this.rotation});

  factory PlayerState.fromMap(Map<String, dynamic> map) {
    return PlayerState(
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      rotation: map['rotation']?.toDouble() ?? 0.0,
    );
  }
}

class MiniMap extends StatelessWidget {
  final PlayerState playerState;
  final double roomSize;
  final Function(double, double) onTap;
  final double mapSize;

  const MiniMap({
    super.key,
    required this.playerState,
    required this.roomSize,
    required this.onTap,
    this.mapSize = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final double tapX = details.localPosition.dx;
        final double tapY = details.localPosition.dy;
        final double roomX = (tapX / mapSize) * roomSize - (roomSize / 2);
        final double roomZ = (tapY / mapSize) * roomSize - (roomSize / 2);
        onTap(roomX, roomZ);
      },
      child: Container(
        width: mapSize,
        height: mapSize,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: MiniMapPainter(
            playerState: playerState,
            roomSize: roomSize,
          ),
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final PlayerState playerState;
  final double roomSize;

  MiniMapPainter({required this.playerState, required this.roomSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / roomSize;
    final double playerX = (playerState.x + roomSize / 2) * scale;
    final double playerY = (playerState.y + roomSize / 2) * scale;
    canvas.save();
    canvas.translate(playerX, playerY);
    canvas.rotate(-playerState.rotation + pi / 2);

    final playerPaint = Paint()..color = Colors.cyan;
    final path = Path();
    path.moveTo(0, -8);
    path.lineTo(5, 5);
    path.lineTo(-5, 5);
    path.close();
    canvas.drawPath(path, playerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
