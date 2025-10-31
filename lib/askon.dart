import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

// --- Call States ---
enum CallState { idle, searching, foundUser, connected }

// --- NEW: Chat Message Class ---
class ChatMessage {
  final String id;
  final String text;
  final bool isSender;

  ChatMessage({required this.id, required this.text, this.isSender = false});
}

class AskOnPage extends StatefulWidget {
  final ValueChanged<bool> onCallStateChanged;

  const AskOnPage({
    super.key,
    required this.onCallStateChanged,
  });

  @override
  State<AskOnPage> createState() => _AskOnPageState();
}

class _AskOnPageState extends State<AskOnPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool _isMicEnabled = true;

  // --- State Management ---
  CallState _callState = CallState.idle;
  Offset _pipPosition = const Offset(20, 20);
  int _foundUserSeed = 1;

  // --- Camera Controller ---
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;

  // --- Animation ---
  AnimationController? _borderAnimationController;
  Animation<double>? _borderAnimation;

  // --- NEW: Chat State ---
  bool _showChat = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _borderAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _borderAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _borderAnimationController?.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }).catchError((e) {
      debugPrint("Failed to initialize camera: $e");
    });
    if (mounted) setState(() {});
  }

  void _toggleMic() {
    HapticFeedback.vibrate();
    HapticFeedback.selectionClick();
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
  }

  void _startSearch() {
    HapticFeedback.vibrate();
    HapticFeedback.selectionClick();

    if (_callState == CallState.idle) {
      widget.onCallStateChanged(true);
    }

    setState(() {
      _callState = CallState.searching;
    });
    _borderAnimationController?.repeat(reverse: true);

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _callState = CallState.foundUser;
        _foundUserSeed = Random().nextInt(1000);
      });
      _borderAnimationController?.stop();
    });
  }

  void _connectToUser() {
    HapticFeedback.vibrate();
    HapticFeedback.selectionClick();

    setState(() {
      _callState = CallState.connected;
      _messages.clear(); // Clear old messages
      _showChat = true; // Show chat by default
    });

    // --- NEW: Add a dummy message from the stranger ---
    Timer(const Duration(seconds: 2), () {
      if (!mounted || _callState != CallState.connected) return;
      setState(() {
        _messages.add(ChatMessage(
          id: 'stranger_1',
          text: 'Hey, nice to meet you!',
          isSender: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _skipUser() {
    _startSearch();
  }

  void _endCall() {
    HapticFeedback.vibrate();
    HapticFeedback.selectionClick();

    widget.onCallStateChanged(false);

    setState(() {
      _callState = CallState.idle;
      _pipPosition = const Offset(20, 20);
      _messages.clear();
      _showChat = false;
    });
  }

  // --- NEW: Chat Functions ---
  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isSender: true, // This is the user
      ));
    });
    _chatController.clear();
    _scrollToBottom();
    // In a real app, you would send this message to the other user via your backend
  }

  void _scrollToBottom() {
    // Scroll to the bottom after a short delay
    Timer(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController
            .jumpTo(_chatScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- STATE 4: Connected ---
          if (_callState == CallState.connected) _buildStrangerVideoFeed(),

          // --- STATE 1, 2, 3: Idle, Searching, FoundUser ---
          AnimatedOpacity(
            opacity: _callState != CallState.connected ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _callState == CallState.connected,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildTopCardSwitcher(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _buildCameraPreviewContainer(),
                      ),
                      const SizedBox(height: 24),
                      _buildBottomButtonSwitcher(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- STATE 4: Draggable PiP Camera ---
          if (_callState == CallState.connected)
            _buildDraggablePipCamera(screenSize),

          // --- STATE 4: Chat UI ---
          if (_callState == CallState.connected) _buildChatUI(),

          // --- STATE 4: Call Control Buttons ---
          if (_callState == CallState.connected) _buildCallControls(),
        ],
      ),
    );
  }

  // --- Extracted Widgets ---

  Widget _buildTopCardSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _callState == CallState.foundUser
          ? _buildFoundUserCard(context)
          : _buildInfoCard(context),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      key: const ValueKey('infoCard'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.video_call_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Random Video Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Connect with random people instantly. Have meaningful conversations, make new friends.',
            style:
                TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundUserCard(BuildContext context) {
    return Container(
      key: ValueKey('foundCard_$_foundUserSeed'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: NetworkImage(
                'https://picsum.photos/seed/$_foundUserSeed/80/80'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Found someone!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Do you want to connect?',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreviewContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _borderAnimationController!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: _callState == CallState.searching
                  ? Border.all(
                      color: Colors.green,
                      width: _borderAnimation?.value ?? 2.0,
                    )
                  : Border.all(color: Colors.transparent, width: 0),
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(),
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildMicButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child:
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }
    return Transform.flip(
      flipX: true,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildMicButton({double size = 28}) {
    return GestureDetector(
      onTap: _toggleMic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(size * 0.5),
        decoration: BoxDecoration(
          color: _isMicEnabled
              ? Colors.white.withOpacity(0.9)
              : Colors.red.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  (_isMicEnabled ? Colors.black : Colors.red).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isMicEnabled ? Icons.mic : Icons.mic_off,
          color: _isMicEnabled ? Colors.black87 : Colors.white,
          size: size,
        ),
      ),
    );
  }

  Widget _buildBottomButtonSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _callState == CallState.foundUser
          ? _buildConnectSkipButtons()
          : _buildStartButton(),
    );
  }

  Widget _buildStartButton() {
    bool isSearching = _callState == CallState.searching;

    return GestureDetector(
      key: const ValueKey('startButton'),
      onTapDown: (_) {
        HapticFeedback.vibrate();
        HapticFeedback.selectionClick();
      },
      onTap: isSearching ? null : _startSearch,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: isSearching ? Colors.grey.shade600 : const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(32.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isSearching ? 'SEARCHING...' : 'START',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectSkipButtons() {
    return Row(
      key: const ValueKey('connectSkipButtons'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTapDown: (_) {
              HapticFeedback.vibrate();
              HapticFeedback.selectionClick();
            },
            onTap: _skipUser,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(32.5),
              ),
              child: Center(
                child: Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) {
              HapticFeedback.vibrate();
              HapticFeedback.selectionClick();
            },
            onTap: _connectToUser,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(32.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'CONNECT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrangerVideoFeed() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 100, color: Colors.grey[700]),
            const SizedBox(height: 20),
            Text(
              'Connected to stranger',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePipCamera(Size screenSize) {
    const pipWidth = 120.0;
    const pipHeight = 180.0;

    return Positioned(
      left: _pipPosition.dx,
      top: _pipPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            double newDx = (_pipPosition.dx + details.delta.dx)
                .clamp(0.0, screenSize.width - pipWidth);
            double newDy = (_pipPosition.dy + details.delta.dy)
                .clamp(0.0, screenSize.height - pipHeight);
            _pipPosition = Offset(newDx, newDy);
          });
        },
        child: Container(
          width: pipWidth,
          height: pipHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _buildCameraPreview(),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _buildMicButton(size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Chat UI (Twitch Style) ---
  Widget _buildChatUI() {
    return Positioned(
      bottom: 100, // Position above the call controls
      left: 16,
      right: 16,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _showChat ? 220 : 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Message List ---
                    Expanded(
                      child: ListView.builder(
                        controller: _chatScrollController,
                        itemCount: _messages.length,
                        padding: const EdgeInsets.all(8.0),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildChatMessage(message);
                        },
                      ),
                    ),
                    // --- Chat Input Field ---
                    _buildChatInputField(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Single Chat Message Bubble ---
  Widget _buildChatMessage(ChatMessage message) {
    // Style for "Twitch-like" text
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      shadows: [
        Shadow(
          blurRadius: 4.0,
          color: Colors.black.withOpacity(0.7),
          offset: const Offset(1, 1),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: message.isSender ? 'You: ' : 'Stranger: ',
              style: textStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: message.isSender ? Colors.blue[300] : Colors.green[300],
              ),
            ),
            TextSpan(
              text: message.text,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Chat Input Field ---
  Widget _buildChatInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Send a message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // --- NEW: Call Control Buttons (Chat + Hang Up) ---
  Widget _buildCallControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Chat Toggle Button ---
          GestureDetector(
            onTap: _toggleChat,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // --- Hang Up Button ---
          GestureDetector(
            onTap: _endCall,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
