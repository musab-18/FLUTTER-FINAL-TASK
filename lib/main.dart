import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/home_screen.dart';
import 'screens/main/search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/main/notifications_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/posts_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    runApp(const SocialConnectApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Firebase: $e\n\nPlease ensure your Firebase project has been configured for this platform (e.g., Web requires a Web App ID).', textAlign: TextAlign.center),
        ),
      ),
    ));
  }
}

class SocialConnectApp extends StatelessWidget {
  const SocialConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'Social Connect',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1), // Indigo 500
                brightness: Brightness.dark,
                background: const Color(0xFF0F172A), // Slate 900
                surface: const Color(0xFF1E293B), // Slate 800
              ),
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF0F172A), // Match background
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              cardTheme: CardTheme(
                color: const Color(0xFF1E293B),
                elevation: 4,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            home: authProvider.isAuthenticated
                ? const MainScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF6366F1), // Indigo 500
          unselectedItemColor: const Color(0xFF94A3B8), // Slate 400
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), activeIcon: Icon(Icons.home_filled, size: 30), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search, size: 28), activeIcon: Icon(Icons.search, size: 30), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none, size: 28), activeIcon: Icon(Icons.notifications, size: 30), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 28), activeIcon: Icon(Icons.person, size: 30), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
