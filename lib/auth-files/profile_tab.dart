// splitright/lib/auth-files/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileTab extends StatelessWidget {
  Future<void> _signOut(BuildContext context) async {
    // Show confirmation dialog
    bool shouldSignOut = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF000000), // Pitch black
              title: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to sign out?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Sign Out'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldSignOut) {
      try {
        // Clear any cached data (if you have any)
        // UserService.clearCache(); // Uncomment if you add caching

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully signed out',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error signing out: $e',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFF000000), // Pitch black
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF000000), // Pitch black
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFF000000), // Pitch black
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF111111), // Very dark gray
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              Text(
                user?.email ?? 'No email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              // Email verification status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user?.emailVerified == true
                      ? Color(0xFF001100) // Very dark green
                      : Color(0xFF331100), // Very dark orange
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user?.emailVerified == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user?.emailVerified == true
                          ? Icons.verified
                          : Icons.warning,
                      size: 16,
                      color: user?.emailVerified == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      user?.emailVerified == true
                          ? 'Email Verified'
                          : 'Email Not Verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: user?.emailVerified == true
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Resend verification email button (if not verified)
              if (user?.emailVerified == false) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await user?.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Verification email sent!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error sending verification email: $e',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.email, color: Colors.white),
                  label: Text(
                    'Resend Verification Email',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Security info
              Container(
                margin: EdgeInsets.symmetric(horizontal: 32),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF001100), // Very dark green
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade800),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your account is protected by:',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Firebase Authentication',
                          style: TextStyle(color: Colors.green.shade400),
                        ),
                        Text(
                          '• Encrypted data storage',
                          style: TextStyle(color: Colors.green.shade400),
                        ),
                        Text(
                          '• Secure database rules',
                          style: TextStyle(color: Colors.green.shade400),
                        ),
                        if (user?.emailVerified == true)
                          Text(
                            '• Verified email address',
                            style: TextStyle(color: Colors.green.shade400),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Sign out button
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
