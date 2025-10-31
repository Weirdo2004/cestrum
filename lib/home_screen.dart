import 'package:ces/askon.dart';
import 'package:ces/engage.dart';
import 'package:ces/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int? _pressedIndex;
  String? _photoURL;
  bool _hideNavigation = false; // New state to control navigation visibility

  late AnimationController _navigationAnimationController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _bottomNavSlideAnimation;
  late Animation<double> _fadeAnimation;

  // List of pages (3 tabs)
  late final List<Widget> _pages;

  // List of titles (3 tabs)
  static const List<String> _pageTitles = <String>[
    'AskOn',
    'Engage',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserPhoto();

    // Initialize animation controller
    _navigationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _appBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _navigationAnimationController,
      curve: Curves.easeInOut,
    ));

    _bottomNavSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: _navigationAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _navigationAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize pages with callback
    _pages = [
      AskOnPage(
        // --- FIX: Corrected parameter name ---
        onCallStateChanged: _handleConnectionChanged,
      ),
      const EngagePage(),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _navigationAnimationController.dispose();
    super.dispose();
  }

  // Callback to handle connection state from AskOnPage
  void _handleConnectionChanged(bool isConnected) {
    setState(() {
      _hideNavigation = isConnected;
    });

    if (isConnected) {
      _navigationAnimationController.forward();
    } else {
      _navigationAnimationController.reverse();
    }
  }

  Future<void> _fetchUserPhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (docSnapshot.exists && docSnapshot.data() != null) {
          if (mounted) {
            setState(() {
              _photoURL = docSnapshot.data()!['photoURL'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching photo URL for tab bar: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildNavItem(IconData icon, int index, {bool hasBadge = false}) {
    final isSelected = _selectedIndex == index;
    final color =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400];

    Widget iconWidget = Icon(icon, size: 28, color: color);

    if (hasBadge) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.5,
                  color: const Color(0xFF2E2E2E),
                ),
              ),
            ),
          )
        ],
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.vibrate();
        HapticFeedback.selectionClick();
        setState(() {
          _pressedIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressedIndex = null;
        });
        _onItemTapped(index);
      },
      onTapCancel: () {
        setState(() {
          _pressedIndex = null;
        });
      },
      child: iconWidget,
    );
  }

  Widget _buildProfileTab(int index) {
    final isSelected = _selectedIndex == index;
    final selectedColor = Theme.of(context).colorScheme.primary;

    Widget tabContent;

    if (_photoURL != null) {
      tabContent = CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(_photoURL!),
      );

      if (isSelected) {
        tabContent = CircleAvatar(
          radius: 16,
          backgroundColor: selectedColor,
          child: tabContent,
        );
      }
    } else {
      tabContent = Icon(
        Icons.person_outline,
        size: 28,
        color: isSelected ? selectedColor : Colors.grey[400],
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.vibrate();
        HapticFeedback.selectionClick();
        setState(() {
          _pressedIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressedIndex = null;
        });
        _onItemTapped(index);
      },
      onTapCancel: () {
        setState(() {
          _pressedIndex = null;
        });
      },
      child: tabContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    Matrix4 transform = Matrix4.identity();

    if (_pressedIndex != null) {
      transform.setEntry(3, 2, 0.001);
      double rotationZ = (_pressedIndex! - 1.0) * 0.08;
      transform.rotateX(0.05);
      transform.rotateZ(rotationZ);
      transform.translate(0.0, 3.0, 0.0);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _hideNavigation
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: SlideTransition(
                position: _appBarSlideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AppBar(
                    systemOverlayStyle: const SystemUiOverlayStyle(
                      statusBarIconBrightness: Brightness.dark,
                      statusBarBrightness: Brightness.light,
                    ),
                    title: Text(_pageTitles[_selectedIndex]),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    titleTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    iconTheme: const IconThemeData(
                      color: Colors.black87,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => _logout(context),
                        tooltip: 'Log Out',
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: _hideNavigation
          ? null
          : SlideTransition(
              position: _bottomNavSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    transform: transform,
                    transformAlignment: Alignment.center,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(32.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.question_answer_outlined, 0),
                        _buildNavItem(Icons.groups_outlined, 1, hasBadge: true),
                        _buildProfileTab(2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
