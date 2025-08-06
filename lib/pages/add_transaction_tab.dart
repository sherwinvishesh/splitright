// splitright/lib/pages/add_transaction_tab.dart
import 'package:flutter/material.dart';

class AddTransactionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000), // Pitch black
      appBar: AppBar(
        title: Text(
          'Add Transaction',
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
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'The pages are yet to come',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Add new transactions here soon!',
                style: TextStyle(
                  fontSize: 16,
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
