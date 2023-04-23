//
// main.dart
// SyncIn
//
// Created by ethereus on 13/02/23
// Copyright © 2023 ethereus. All rights reserved.
//

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_clean_calendar/flutter_clean_calendar.dart';
import 'package:flutter/services.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_background/flutter_background.dart';

late SharedPreferences prefs;
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterBackground.initialize();
  prefs = await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncIn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: SignInScreen(),
    );
  }
}

bool isInsideEvent(DateTime dateTime, Map<DateTime, List<CleanCalendarEvent>> events) {
  for (final List<CleanCalendarEvent> eventList in events.values) {
    for (final CleanCalendarEvent event in eventList) {
      // Check if the provided DateTime is between the start and end times of the event
      if (dateTime.isAfter(event.startTime) && dateTime.isBefore(event.endTime)) {
        return true;
      }
    }
  }
  return false;
}


void startBackgroundProcess(Map<DateTime, List<CleanCalendarEvent>> events) {
  final _auth = FirebaseAuth.instance;

  String code = '';

  String? savedCode = prefs.getString('code');

  if (savedCode != null) {
    code = savedCode;
  }

  DateTime now = DateTime.now();

  bool isInside = isInsideEvent(now, events);
  String status = isInside ? "busy" : "free";

  print("User is currently $status");

  // Set the callback function that will be called by the plugin every time the background process is triggered.
  FlutterBackground.enableBackgroundExecution().then((value) {

    //change to minutes: 15 for release

    Timer.periodic(Duration(minutes: 15), (timer) async {
      // Get a reference to the Firebase Realtime Database instance
      DatabaseReference reference = FirebaseDatabase.instance.reference();

    String displayName = _auth.currentUser!.displayName.toString();
    String freeTimePath = 'free_time/' + code;

    // Remove existing entry
    await reference.child(freeTimePath + displayName).remove();

    // Push new data to the database
    //change to user code not name for release
    await reference.child(freeTimePath + displayName).set({
      displayName: status,
      // add your data here
    });

      // Log the success of the push operation
      //print("Data pushed to Firebase Realtime Database");
    });
  });
}

class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;

  CopyableText({
    Key key = const ValueKey('default_key'),
    required this.text,
    this.style = const TextStyle(),
    this.textAlign = TextAlign.center,
    this.maxLines = 13,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Copied to clipboard")),
        );
      },
      child: SizedBox(
        child: SelectableText(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.reference();
  final _messageController = TextEditingController();
  List<Map<dynamic, dynamic>> _messages = [];

  String code = '';

  @override
  void initState() {
    super.initState();

    String? savedCode = prefs.getString('code');

    if (savedCode != null) {
      code = savedCode;
    }

    // Listen for changes in the Firebase database
    _database.child('group_chat_messages/' + code).onChildAdded.listen((event) {
      setState(() {
        var messageHolder = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        _messages.add(messageHolder);
      });
    });
  }

  void _sendMessage(String message) {
    // Add the message to the Firebase database
    _database.child('group_chat_messages/' + code).push().set({
      'sender': _auth.currentUser!.displayName,
      'message': message,
      'timestamp':  ServerValue.timestamp,
    });
    // Clear the message input field
    _messageController.clear();
  }

  //function go here fml

  Future<List> icsToEvent(fileLocation) async {
    List events = [];

    // fileLocation needs to be in the format of 'assets/test_data_.ics'
    final icsString = await rootBundle.loadString(fileLocation);
    final iCalendar = ICalendar.fromString(icsString);
    final iCalJSON = iCalendar.toJson();
    final iCalData = iCalJSON['data'];
    for (final event in iCalData) {
      events.add(CleanCalendarEvent(event['summary'],
          startTime: parseDateString(event['dtstart']),
          endTime: parseDateString(event['dtend']),
          color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(1.0)));
    }
    print("ITS HERE:");
    print(events);
    print("ITS AVOVE HERE");
    return events;
  }

  DateTime parseDateString(String input) {
    RegExp regex =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}).(\d{3})Z$');
    Match match = regex.firstMatch(input) as Match;
    int year = int.parse(match.group(0)!);
    int month = int.parse(match.group(1)!);
    int day = int.parse(match.group(2)!);
    int hour = int.parse(match.group(3)!);
    int minute = int.parse(match.group(4)!);
    int second = int.parse(match.group(5)!);
    int millisecond = int.parse(match.group(6)!);
    return DateTime.utc(year, month, day, hour, minute, second, millisecond);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Chat'),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/calendar.png'),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CalendarApp(),
                ),
              );
            },
          ),
          IconButton(
            icon: Image.asset('assets/images/logout.png'),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => UserInfoScreen(
                    user: FirebaseAuth.instance.currentUser!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]['message']),
                  subtitle: Text(_messages[index]['sender']),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_messageController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IcsScreen extends StatefulWidget {
  @override
  _IcsScreenState createState() => _IcsScreenState();
}

class _IcsScreenState extends State<IcsScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.reference();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload'),
        leading: IconButton(
          icon: Image.asset('assets/images/calendar.png'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CalendarApp(),
              ),
            );
          },
        ),
      ),
      body: Center(
          child: ElevatedButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform
              .pickFiles(type: FileType.custom, allowedExtensions: ['ics']);
          if (result != null) {
            PlatformFile file = result.files.single;

            final appStorage = await getApplicationDocumentsDirectory();
            final newFile =
                File('${appStorage.path}/assests/icsFiles/${file.name}');

            //we do here what must be done

            List events = [];
            String? pleaseWork;
            // fileLocation needs to be in the format of 'assets/test_data_.ics'
            //final icsLines = await File(file.path!).readAsLines();
            //final iCalendar = ICalendar.fromLines(icsLines);

            final icsString = await rootBundle
                .loadString(newFile.path)
                .then((String icsString) {
              pleaseWork = icsString;
            });

            // The issue that the program doesn't recongize the cached .ics file as an asset so its unable to do anything
            // A fix is store it somewhere under a reuseable name then delete after accessed and processed it.
            // Then we update the .yaml file so it can recongize the asset and load it.

            final iCalendar = ICalendar.fromString(pleaseWork!);
            final iCalJSON = iCalendar.toJson();
            final iCalData = iCalJSON['data'];
            for (final event in iCalData) {
              events.add(CleanCalendarEvent(event['summary'],
                  startTime: DateTime.parse(event['dtstart']),
                  endTime: DateTime.parse(event['dtend']),
                  color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
                      .withOpacity(1.0)));
            }
            newFile.delete();
            for (final event in events) {
              print(event);
            }
          }
        },
        child: Text("Select File"),
      )),
    );
  }
}

class Authentication {
  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User? user = FirebaseAuth.instance.currentUser;

    //uncomment to enable automatic sign in (should remove signing out button from user info if we do this)

    //if (user != null) {
    //Navigator.of(context).pushReplacement(
    //MaterialPageRoute(
    //builder: (context) => GroupChatScreen(),
    //),
    //);
    //}

    return firebaseApp;
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        Authentication.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );
    }
  }

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      try {
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);

        user = userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            Authentication.customSnackBar(
              content:
                  'The account already exists with a different credential.',
            ),
          );
        } else if (e.code == 'invalid-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            Authentication.customSnackBar(
              content: 'Error occurred while accessing credentials. Try again.',
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          Authentication.customSnackBar(
            content: 'Error occurred using Google Sign-In. Try again.',
          ),
        );
      }
    }

    return user;
  }
}

class GroupChoiceScreen extends StatefulWidget {
  @override
  _GroupChoiceScreenState createState() => _GroupChoiceScreenState();
}

class _GroupChoiceScreenState extends State<GroupChoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => JoinGroupScreen(),
                          ),
                         );
                },
                child: Text(
                  'Join a Group',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 32.0,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => GroupCodeScreen(),
                          ),
                         );
                },
                child: Text(
                  'Create a Group',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 32.0,
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

class GroupCodeScreen extends StatefulWidget {
  @override
  _GroupCodeScreenState createState() => _GroupCodeScreenState();
}

class _GroupCodeScreenState extends State<GroupCodeScreen> {
  String _groupCode = '';

  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    _groupCode = _generateGroupCode();
  }

  String _generateGroupCode() {
    const String chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    math.Random rnd = new math.Random();
    String code = "";
    for (var i = 0; i < 13; i++) {
      code += chars[rnd.nextInt(chars.length)];
    }
    return code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your group code:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            CopyableText(
                text: '$_groupCode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            SizedBox(height: 16.0),
            Text(
              'You can view this in the logout screen at any time',
              style: TextStyle(
                fontSize: 18.0,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {

                prefs.setString('code', _groupCode);

                final String name = _auth.currentUser!.displayName.toString();

                _database.child('group_chat_messages/$_groupCode').push().set({
                  'sender': "SyncIn",
                  'message': "$name has joined the group.",
                  'timestamp': ServerValue.timestamp,
                });

                Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => CalendarApp(),
                          ),
                         );
              },
              child: Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinGroupScreen extends StatefulWidget {
  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  static String code = '.';
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 160,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Enter group code:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "eg. x0fVJROgkdLAOcWaAAervVhsmxg7",
                      ),
                      onChanged: (enteredCode) {
                        code = enteredCode;
                        prefs.setString('code', code);
                      },
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Colors.white,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () async {

                        final String name = _auth.currentUser!.displayName.toString();

                        _database.child('group_chat_messages/$code').push().set({
                          'sender': "SyncIn",
                          'message': "$name has joined the group.",
                          'timestamp': ServerValue.timestamp,
                        });

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => CalendarApp(),
                          ),
                         );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 2,
                          ),
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

class GoogleSignInButton extends StatefulWidget {
  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _isSigningIn
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              onPressed: () async {
                setState(() {
                  _isSigningIn = true;
                });

                User? user =
                    await Authentication.signInWithGoogle(context: context);

                setState(() {
                  _isSigningIn = false;
                });

                String code = '.';

                String? savedCode = prefs.getString('code');

                if (savedCode != null) {
                  code = savedCode;
                }

                if (user != null && code == '.') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => GroupChoiceScreen(),
                    ),
                  );
                }

                if (user != null && code != '.') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => CalendarApp(),
                    ),
                  );
                }

              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image(
                      image: AssetImage("assets/images/google_logo.png"),
                      height: 35.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 160,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'SyncIn',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 40,
                      ),
                    ),
                    Text(
                      'Authentication',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder(
                future: Authentication.initializeFirebase(context: context),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error initializing Firebase');
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    return GoogleSignInButton();
                  }
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late User _user;
  bool _isSigningOut = false;

  String code = '';

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  void initState() {
    _user = widget._user;

    String? savedCode = prefs.getString('code');

    if (savedCode != null) {
      code = savedCode;
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        title: const Text('Sign Out'),
        leading: IconButton(
          icon: Image.asset('assets/images/calendar.png'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CalendarApp(),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(),
              _user.photoURL != null
                  ? ClipOval(
                      child: Material(
                        color: Colors.blueGrey.withOpacity(0.3),
                        child: Image.network(
                          _user.photoURL!,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Material(
                        color: Colors.grey.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 16.0),
              Text(
                'Hello',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                _user.displayName!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                '( ${_user.email!} )',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Group code:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.0),
              CopyableText(
                text: '$code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 24.0),
              Text(
                'You are now signed in using your Google account. To sign out of your account, click the "Sign Out" button below.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    letterSpacing: 0.2),
              ),
              SizedBox(height: 16.0),
              _isSigningOut
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Colors.redAccent,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          _isSigningOut = true;
                        });
                        await Authentication.signOut(context: context);
                        setState(() {
                          _isSigningOut = false;
                        });
                        Navigator.of(context)
                            .pushReplacement(_routeToSignInScreen());
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarApp extends StatefulWidget {
  @override
  _CalendarAppState createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  void _handleData(date) {
    setState(() {
      selectedDay = date;
      selectedEvent = events[selectedDay] ?? [];
    });
  }

  // ---free time functions---

  Map<DateTime, List<CleanCalendarEvent>> findFreeTime(user1, user2) {
    Map<DateTime, List<CleanCalendarEvent>> user1FreeTime = user1;
    Map<DateTime, List<CleanCalendarEvent>> user2FreeTime = user2;

    List<DateTime> user1Times = [];
    List<DateTime> user2Times = [];

    user1FreeTime.forEach((key, value) {
      user1Times.add(key);
    });
    user2FreeTime.forEach((key, value) {
      user2Times.add(key);
    });

    user1Times.sort(((a, b) => a.compareTo(b)));
    user2Times.sort(((a, b) => a.compareTo(b)));

    // freeTime will store all the time where the to users are free [[startTime,endTime]]
    Map<DateTime, List<CleanCalendarEvent>> freeTimeMap = {};

    for (final day in user1Times) {
      // ignore: unrelated_type_equality_checks
      Object? temp;
      try {
        temp = user2FreeTime[day];
      } catch (e) {
        temp = Null;
      }
      if (temp != Null) {
        List<CleanCalendarEvent> user2Events = temp as List<CleanCalendarEvent>;
        List<CleanCalendarEvent> user1Events = user1FreeTime[day]!;
        List<CleanCalendarEvent> freeTimeList = [];

        int events1Ptr = 0;
        int events2Ptr = 0;

        while (user1Events.length > events1Ptr &&
            user2Events.length > events2Ptr) {
          if (user1Events[events1Ptr]
              .endTime
              .isBefore(user2Events[events2Ptr].startTime)) {
            // The events do not overlap at all
            events1Ptr++;
          } else if (user2Events[events2Ptr]
              .endTime
              .isBefore(user1Events[events1Ptr].startTime)) {
            events2Ptr++;
          } else if (user1Events[events1Ptr]
                  .startTime
                  .isBefore(user2Events[events2Ptr].startTime) &&
              user1Events[events1Ptr]
                  .endTime
                  .isBefore(user2Events[events2Ptr].endTime) &&
              user1Events[events1Ptr]
                  .endTime
                  .isAfter(user2Events[events2Ptr].startTime)) {
            // The start of user1Events[events1Ptr] overlaps with user2Events[events2Ptr]
            freeTimeList.add(CleanCalendarEvent("Free Time",
                startTime: user2Events[events2Ptr].startTime,
                endTime: user1Events[events1Ptr].endTime));
            events1Ptr++;
          } else if (user1Events[events1Ptr]
                  .startTime
                  .isBefore(user2Events[events2Ptr].endTime) &&
              user1Events[events1Ptr]
                  .endTime
                  .isAfter(user2Events[events2Ptr].endTime)) {
            // user1Events[events1Ptr] completely contains user2Events[events2Ptr]
            freeTimeList.add(CleanCalendarEvent("Free Time",
                startTime: user2Events[events2Ptr].startTime,
                endTime: user2Events[events2Ptr].endTime));
            events2Ptr++;
          } else if (user2Events[events2Ptr]
                  .startTime
                  .isBefore(user1Events[events1Ptr].startTime) &&
              user2Events[events2Ptr]
                  .endTime
                  .isBefore(user1Events[events1Ptr].endTime) &&
              user2Events[events2Ptr]
                  .endTime
                  .isAfter(user1Events[events1Ptr].startTime)) {
            // The start of user2Events[events2Ptr] overlaps with user1Events[events1Ptr]
            freeTimeList.add(CleanCalendarEvent("Free Time",
                startTime: user1Events[events1Ptr].startTime,
                endTime: user2Events[events2Ptr].endTime));
            events2Ptr++;
          } else if (user2Events[events2Ptr]
                  .startTime
                  .isBefore(user1Events[events1Ptr].endTime) &&
              user2Events[events2Ptr]
                  .endTime
                  .isAfter(user1Events[events1Ptr].endTime)) {
            // user2Events[events2Ptr] completely contains user1Events[events1Ptr]
            freeTimeList.add(CleanCalendarEvent("Free Time",
                startTime: user1Events[events1Ptr].startTime,
                endTime: user1Events[events1Ptr].endTime));
            events1Ptr++;
          } else {
            // The events overlap, but neither completely contains the other
            DateTime overlapStart = user1Events[events1Ptr]
                    .startTime
                    .isAfter(user2Events[events2Ptr].startTime)
                ? user1Events[events1Ptr].startTime
                : user2Events[events2Ptr].startTime;
            DateTime overlapEnd = user1Events[events1Ptr]
                    .endTime
                    .isBefore(user2Events[events2Ptr].endTime)
                ? user1Events[events1Ptr].endTime
                : user2Events[events2Ptr].endTime;
            freeTimeList.add(CleanCalendarEvent("Free Time",
                startTime: overlapStart, endTime: overlapEnd));
            if (overlapStart == user1Events[events1Ptr].startTime) {
              events1Ptr++;
            } else if (overlapStart == user2Events[events2Ptr].startTime) {
              events2Ptr++;
            }
          }
        }
        freeTimeMap[day] = freeTimeList;
        user1Times.remove(day);
        user2Times.remove(day);
      } else {
        List<CleanCalendarEvent> value = user1FreeTime[day]!;
        value.sort(((a, b) => a.startTime.compareTo(b.startTime)));
        List<CleanCalendarEvent> freeTime = [];
        DateTime freeEndTime;
        DateTime freeStartTime = day;
        for (int i = 0; i < events.length; i++) {
          freeEndTime = value[i].startTime;
          freeTime.add(CleanCalendarEvent(
            "Free Time",
            startTime: freeStartTime,
            endTime: freeEndTime,
          ));
          freeStartTime = value[i].endTime;
        }
        freeTime.add(CleanCalendarEvent("Free Time", startTime: freeStartTime, endTime: day.add(const Duration(days: 1))));
        freeTimeMap[day] = freeTime;
        user1Times.remove(day);
      }
    }
    if (user2Times.isNotEmpty) {
      for (final day in user2Times) {
        List<CleanCalendarEvent> value = user2FreeTime[day]!;
        value.sort(((a, b) => a.startTime.compareTo(b.startTime)));
        List<CleanCalendarEvent> freeTime = [];
        DateTime freeEndTime;
        DateTime freeStartTime = day;
        for (int i = 0; i < events.length; i++) {
          freeEndTime = value[i].startTime;
          freeTime.add(CleanCalendarEvent(
            "Free Time",
            startTime: freeStartTime,
            endTime: freeEndTime,
          ));
          freeStartTime = value[i].endTime;
        }
        freeTime.add(CleanCalendarEvent("Free Time", startTime: freeStartTime, endTime: day.add(const Duration(days: 1))));
        freeTimeMap[day] = freeTime;
      }
    }
    return freeTimeMap;
  }

  Map<DateTime, List<CleanCalendarEvent>> findUserFreeTime(pasEvents) {
    Map<DateTime, List<CleanCalendarEvent>> events = pasEvents;
    Map<DateTime, List<CleanCalendarEvent>> freeTimeMap = {};

    events.forEach((key, value) {
      value.sort(((a, b) => a.startTime.compareTo(b.startTime)));
      List<CleanCalendarEvent> freeTime = [];
      DateTime freeEndTime;
      DateTime freeStartTime = key;
      for (int i = 0; i < events.length - 1; i++) {
        freeEndTime = value[i].startTime;
        freeTime.add(CleanCalendarEvent(
          "Free Time",
          startTime: freeStartTime,
          endTime: freeEndTime,
        ));
        freeStartTime = value[i].endTime;
      }
      freeTime.add(CleanCalendarEvent("Free Time", startTime: freeStartTime, endTime: key.add(const Duration(days: 1))));

      freeTimeMap[key] = freeTime;
    });

    return freeTimeMap;
  }

// --- end find free time---

  DateTime? selectedDay;
  List<CleanCalendarEvent>? selectedEvent;
  
  Map<DateTime, List<CleanCalendarEvent>> events = {
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 9, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 10, 45),
        description: "busy",
      ),
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 12, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 13, 15),
        description: "busy",
      ),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1):
        [
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 9, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 10, 45),
        description: "busy",
      ),
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 15, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 16, 15),
        description: "busy",
      ),
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 16, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 18, 15),
        description: "busy",
      ),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 3):
        [
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 12, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 13, 15),
        description: "busy",
      ),
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 13, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 15, 15),
        description: "busy",
      ),
      CleanCalendarEvent(
        'Busy',
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 15, 15),
        endTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 16, 15),
        description: "busy",
      ),
    ]
  };

  @override
void initState() {
  super.initState();
  startBackgroundProcess(events);
}

  Future<void> uploadEventDataToFirebase(
    Map<DateTime, List<CleanCalendarEvent>> events) async {


    final _database = FirebaseDatabase.instance.reference();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final currentUser = _auth.currentUser;
    print(currentUser);

    if (currentUser != null) {
      events.forEach((key, element) {
        for (final event in element) {
          // check if in database then don't run

          var dataRetrieved = _database
              .child('user_tables')
              .child(currentUser.uid)
              .orderByChild("startTime")
              .equalTo(event.startTime.toString());

          //dataRetrieved.on(event.startTime.toString(), function(snapshot) {
          //if(!snapshot.exists()){
          _database.child('free_time').child(currentUser.uid).push().set({
            'day': key.toString(),
            'summary': event.summary.toString(),
            'startTime': event.startTime.toString(),
            'endTime': event.endTime.toString(),
          });
          //}
          //});
        }
      });
    }
  }


  void createTableForCurrentUser() {
    
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseDatabase _database = FirebaseDatabase.instance;

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userTableRef =
          _database.reference().child('user_tables').child(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    createTableForCurrentUser();
    //uploadEventDataToFirebase(findUserFreeTime(events));
    return Scaffold(
      appBar: AppBar(
        title: Text('SyncIn'),
        leading: IconButton(
          icon: Image.asset('assets/images/upload.png'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => IcsScreen(),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset('assets/images/chat.png'),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Image.asset('assets/images/logout.png'),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => UserInfoScreen(
                    user: FirebaseAuth.instance.currentUser!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          child: Calendar(
            startOnMonday: true,
            selectedColor: Colors.blue,
            todayColor: Colors.red,
            eventColor: Colors.green,
            eventDoneColor: Colors.amber,
            bottomBarColor: Colors.deepOrange,
            onRangeSelected: (range) {
              print('selected Day ${range.from},${range.to}');
            },
            onDateSelected: (date) {
              return _handleData(date);
            },
            events: events,
            isExpanded: true,
            dayOfWeekStyle: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w100,
            ),
            bottomBarTextStyle: TextStyle(
              color: Colors.white,
            ),
            hideBottomBar: false,
            hideArrows: false,
            weekDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Stack(
          children: <Widget>[
            Positioned(
              left: 10.0,
              bottom: 10.0,
              child: FloatingActionButton(
                backgroundColor: Colors.orange,
                onPressed: () {
                  showAddButton(events, context: context);
                },
                child: Icon(Icons.add),
              ),
            ),
            Positioned(
              right: 10.0,
              bottom: 10.0,
              child: FloatingActionButton(
                backgroundColor: Colors.orange,
                onPressed: () {
                  showFreeButton(context: context);
                },
                child: Icon(Icons.group),
              ),
            ),
          ],
        ),
    );
  }
}

void showAddButton(Map<DateTime, List<CleanCalendarEvent>> events, {required BuildContext context}) {
  String title = '';
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  DateTime selectedDate = DateTime.now();

  // Show modal bottom sheet with input fields and date picker
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 350,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Enter event title",
              ),
              onChanged: (enteredText) {
                title = enteredText;
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // Show date picker and update selected date
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime(DateTime.now().year + 5),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: Text('Select Date'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Start Time'),
                    ElevatedButton(
                      onPressed: () async {
                        // Show time picker and update start time
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          startTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute,
                          );
                        }
                      },
                      child: Text('Select Start Time'),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('End Time'),
                    ElevatedButton(
                      onPressed: () async {
                        // Show time picker and update end time
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          endTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute,
                          );
                        }
                      },
                      child: Text('Select End Time'),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              child: Text("Add Event"),
              onPressed: () {
                // Create a new CleanCalendarEvent object with the entered data
                CleanCalendarEvent newEvent = CleanCalendarEvent(
                  title,
                  startTime: startTime,
                  endTime: endTime,
                  description: " ",
                  color: Colors.blue,
                );
                // Add the new event to the events map

                Map<DateTime, List<CleanCalendarEvent>> calendarEvent = {
                  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 3):
                    [
                    CleanCalendarEvent(
                      title,
                      startTime: startTime,
                      endTime: endTime,
                      description: title,
                    ),
                  ]
                };



                if (events[selectedDate] != null) {

                  events[selectedDate]!.add(newEvent);

                } else {

                  events[selectedDate] = [newEvent];
                }
                // Close the modal bottom sheet
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

void showFreeButton({required BuildContext context}) {
  String title = '';

  final databaseReference = FirebaseDatabase.instance.reference();

  // Create a reference to the freeTimePath node
  String freeTimePath = "/free_time/";

  // Create a list to store the displayName and status entries
  List displayNamesAndStatuses = [];

  // Retrieve the data from the database
  databaseReference.child(freeTimePath).onValue.listen((event) {
    // Get the data from the event snapshot
    DataSnapshot snapshot = event.snapshot;
    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>; // Cast value to Map<dynamic, dynamic>
    if (data != null) {
      // Loop through the child nodes of the data
      data.forEach((key, value) {
        // Get the displayName and status values
        String displayName = key.toString();
        String status = value.toString();
        // Add the displayName and status values to the list
        if (status != null) {
          displayNamesAndStatuses.add({
            displayName: status,
          });
        }
      });
    }

    // Show modal bottom sheet for free status
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          child: Column(
            children: [
              Text("Friends List:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0)),
              Flexible(
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayNamesAndStatuses.length,
                  itemBuilder: (BuildContext context, int index) {
                    // Get the current name and status from the list
                    Map<String, dynamic> entry = displayNamesAndStatuses[index];
                    String name = entry.keys.first;
                    String status = entry.values.first;
                    // Split the name and status by the ":" separator
                    List<String> parts = name.split(':');
                    String statusPart = status;
                    if (parts.length > 1) {
                      statusPart = parts[1];
                    }
                    String statusString = statusPart.substring(1, statusPart.length - 1);
                    // Build the widget for the name and status pair
                    return ListTile(
                      title: Text(statusString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                    );
                  },
                ),
              ),
              ElevatedButton(
                child: Text("Close"),
                onPressed: () {
                  // Close the modal bottom sheet
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  });
}