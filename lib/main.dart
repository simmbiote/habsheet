import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabSheet',
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "1044671409623-l99j29r2j6q1tj42inerq82dsrv606ve.apps.googleusercontent.com", // Web client id
    scopes: ['email'],
  );
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HabitSelectionScreen(userEmail: _currentUser!.email)),
        );
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      print("User Signed In: ${account?.email}");

      if (account != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HabitSelectionScreen(userEmail: account.email)),
        );
      }
    } catch (error) {
      print("Sign-In Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Center(
        child: ElevatedButton(
          onPressed: _handleSignIn,
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}

class HabitSelectionScreen extends StatefulWidget {
  final String userEmail;

  HabitSelectionScreen({required this.userEmail});

  @override
  _HabitSelectionScreenState createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  final TextEditingController _habitController = TextEditingController();
  List<String> habits = [];

  Future<void> _createHabitSheet() async {
    final url = Uri.parse(
        "https://script.google.com/macros/s/AKfycbxNTSgY4f_LvUifX0B9A6yBhGiGrhLTmWQBjb9deVZJFMQmUOtJppKvi6jkdwyBRcABUQ/exec");

    // Get Google Sign-In token
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final String? idToken = googleAuth?.idToken;

    if (idToken == null) {
      print("Error: Unable to retrieve Google ID Token");
      return;
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({
        "action": "create",
        "userEmail": widget.userEmail,
        "habits": habits
      }),
    );

    print("Response: ${response.body}");
    print("Status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Google Sheet Created!")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    }
  }

  void _addHabit() {
    if (_habitController.text.isNotEmpty) {
      setState(() {
        habits.add(_habitController.text);
        _habitController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configure Habits')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _habitController,
              decoration: InputDecoration(
                labelText: "Enter habit name",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addHabit,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(habits[index]),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _createHabitSheet,
            child: Text("Create Google Sheet"),
          ),
          ElevatedButton(
            onPressed: _createHabitSheet,
            child: Text("Sign out"),
          ),
        ],
      ),
    );
  }
}
