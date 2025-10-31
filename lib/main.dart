import 'package:ces/home_screen.dart';
import 'package:ces/interactive_widget.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'signup/signup_screen.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  // --- END FIREBASE ---

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- YOUR THEME (UNTOUCHED) ---
    const Color primaryColor = Color(0xFFB3CFE5); // Your new light blue
    const Color primaryVariant =
        Color(0xFF89A4B8); // A darker shade for buttons/variants
    const Color primaryLight =
        Color(0xFFB3CFE5); // A lighter shade for gradients

    const Color backgroundColor = Color(0xFF2C6485);
    const Color surfaceColor = Color(0xFF1E1E1E);

    return MaterialApp(
      title: 'Student Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: primaryColor,
          surface: surfaceColor,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          error: Color(0xFFCF6679),
          onError: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme:
              IconThemeData(color: primaryColor), // Make back arrows blue
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
                color: primaryColor, width: 1.5), // Highlight on focus
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor.withOpacity(0.5);
            }
            return null;
          }),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryVariant;
            }
            return surfaceColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return primaryColor;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          side: WidgetStateProperty.all(BorderSide.none),
        )),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return surfaceColor;
          }),
          checkColor: WidgetStateProperty.all(Colors.black),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, go to HomePage
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const WelcomeScreen();
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveGridBackground(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF89A4B8).withOpacity(0.6),
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      SizedBox(
                        height: 300,
                        child: Lottie.asset(
                          'assets/student_animation.json',
                        ),
                      ),
                      Text(
                        'Find Your Wave',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connect with students just like you. Anonymously or not.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      FuturisticRippleButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        isElevated: true,
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 16),
                      FuturisticRippleButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        isElevated: false,
                        child: const Text('Sign Up'),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
