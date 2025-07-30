import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileTab extends StatelessWidget {
  Future<void> _signOut(BuildContext context) async {
    // Show confirmation dialog
    bool shouldSignOut = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Sign Out'),
                ],
              ),
              content: Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
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
            content: Text('Successfully signed out'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 20),
            Text(
              user?.email ?? 'No email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            // Email verification status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user?.emailVerified == true
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
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
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
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
                        content: Text('Verification email sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending verification email: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.email),
                label: Text('Resend Verification Email'),
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.green[700]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your account is protected by:',
                          style: TextStyle(
                            color: Colors.green[700],
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
                      Text('• Firebase Authentication',
                          style: TextStyle(color: Colors.green[600])),
                      Text('• Encrypted data storage',
                          style: TextStyle(color: Colors.green[600])),
                      Text('• Secure database rules',
                          style: TextStyle(color: Colors.green[600])),
                      if (user?.emailVerified == true)
                        Text('• Verified email address',
                            style: TextStyle(color: Colors.green[600])),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            // Sign out button
            ElevatedButton.icon(
              onPressed: () => _signOut(context),
              icon: Icon(Icons.logout),
              label: Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
