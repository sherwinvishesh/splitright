// splitright/lib/pages/home_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth-files/user_service.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String displayName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? savedDisplayName =
            await UserService.getCurrentUserDisplayName();
        if (savedDisplayName != null && savedDisplayName.isNotEmpty) {
          setState(() {
            displayName = savedDisplayName;
            isLoading = false;
          });
        } else {
          // Fallback to email username
          setState(() {
            displayName = user.email?.split('@')[0] ?? 'User';
            isLoading = false;
          });
        }
      } catch (e) {
        // Fallback on error
        setState(() {
          displayName = user.email?.split('@')[0] ?? 'User';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000), // Pitch black
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF000000), // Pitch black
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFF000000), // Pitch black
        child: Center(
          child: isLoading
              ? CircularProgressIndicator(
                  color: Colors.blue,
                  backgroundColor: Colors.white24,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      size: 80,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Hello, $displayName',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Welcome to SplitRight',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
