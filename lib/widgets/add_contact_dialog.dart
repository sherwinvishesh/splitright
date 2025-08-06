// splitright/lib/widgets/add_contact_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/contacts_service.dart';

class AddContactDialog extends StatefulWidget {
  final VoidCallback onContactAdded;

  const AddContactDialog({Key? key, required this.onContactAdded})
      : super(key: key);

  @override
  _AddContactDialogState createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  String? _userFriendId;

  @override
  void initState() {
    super.initState();
    _loadUserFriendId();
  }

  Future<void> _loadUserFriendId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final friendId = await ContactsService.getUserFriendId(currentUser.uid);
      setState(() {
        _userFriendId = friendId;
      });
    }
  }

  Future<void> _searchAndAddContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final searchQuery = _searchController.text.trim();

      // Check if trying to add their own friend ID
      if (searchQuery.toUpperCase() == _userFriendId) {
        _showErrorSnackBar('You cannot add yourself as a contact');
        setState(() {
          _isSearching = false;
        });
        return;
      }

      // Search for user by friend ID
      final foundUser = await ContactsService.searchUser(searchQuery);

      if (foundUser != null) {
        // Check if contact already exists
        final existingContacts =
            await ContactsService.getUserContacts(currentUser.uid);
        bool contactExists = existingContacts
            .any((contact) => contact['uid'] == foundUser['uid']);

        if (contactExists) {
          _showErrorSnackBar('This user is already in your contacts');
          setState(() {
            _isSearching = false;
          });
          return;
        }

        // User exists, add as contact
        bool success = await ContactsService.addContact(
          currentUser.uid,
          foundUser['uid'],
          foundUser,
        );

        if (success) {
          Navigator.of(context).pop();
          widget.onContactAdded();
          _showSuccessSnackBar(
              '${foundUser['displayName']} added to your contacts!');
        } else {
          _showErrorSnackBar('Failed to add contact');
        }
      } else {
        // User doesn't exist
        _showErrorSnackBar(
            'User not found. Please check the Friend ID and try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _copyFriendId() {
    if (_userFriendId != null) {
      // Copy to clipboard (you might need to add clipboard package)
      _showSuccessSnackBar('Friend ID copied: $_userFriendId');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white24),
      ),
      title: Row(
        children: [
          Icon(Icons.person_add, color: Colors.blue),
          SizedBox(width: 10),
          Text(
            'Add Friend',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show user's own friend ID
              if (_userFriendId != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF001122),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade800),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fingerprint, color: Colors.blue, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Your Friend ID',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _userFriendId!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            GestureDetector(
                              onTap: _copyFriendId,
                              child: Icon(
                                Icons.copy,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Share this ID with friends to connect instantly',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],

              Text(
                'Enter your friend\'s Friend ID',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _searchController,
                style: TextStyle(color: Colors.white, fontSize: 16),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Friend ID',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g. ABC123456789',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.fingerprint, color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF111111),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Friend ID';
                  }
                  if (value.length < 6) {
                    return 'Friend ID must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF001100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade800),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How it works:',
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Each user has a unique Friend ID\n• Share your ID with friends\n• Enter their ID to connect instantly\n• Start texting immediately after connecting',
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSearching ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: _isSearching ? null : _searchAndAddContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSearching
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Add Friend',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
