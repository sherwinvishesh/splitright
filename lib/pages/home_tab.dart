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
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF111111), // Very dark gray
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.waving_hand,
                            size: 48,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Hi, $displayName!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Welcome back to SplitRight',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Color(0xFF001100), // Very dark green
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade800),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your data is securely stored with Firebase!',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
