import 'package:chat_test/icsToEvent.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_clean_calendar/flutter_clean_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show Color, rootBundle;
import 'package:flutter_clean_calendar/clean_calendar_event.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

class GroupChatScreen extends StatefulWidget {
  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.reference();
  final _messageController = TextEditingController();
  List<Map<dynamic, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Listen for changes in the Firebase database
    _database.child('group_chat_messages').onChildAdded.listen((event) {
      setState(() {
        var messageHolder = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        _messages.add(messageHolder);
      });
    });
  }

  void _sendMessage(String message) {
    // Add the message to the Firebase database
    _database.child('group_chat_messages').push().set({
      'sender': _auth.currentUser!.uid,
      'message': message,
      'timestamp': ServerValue.timestamp,
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
                  builder: (context) => DemoApp(),
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
                builder: (context) => DemoApp(),
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

            //we do here what must be done

            List events = [];
            String? pleaseWork;
            // fileLocation needs to be in the format of 'assets/test_data_.ics'
            final icsString = await rootBundle
                .loadString(file.path!)
                .then((String icsString) {
              pleaseWork = icsString;
            });
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

    //uncomment to enable automatic signing in (should remove signing out button from user info if we do this)

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

                if (user != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DemoApp(),
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
                  color: Colors.grey,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                _user.displayName!,
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                '( ${_user.email!} )',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 24.0),
              Text(
                'You are now signed in using your Google account. To sign out of your account, click the "Sign Out" button below.',
                style: TextStyle(
                    color: Colors.grey.withOpacity(0.8),
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

class DemoApp extends StatefulWidget {
  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  void _handleData(date) {
    setState(() {
      selectedDay = date;
      selectedEvent = events[selectedDay] ?? [];
    });
    print(selectedDay);
  }

  void addEvent(DateTime date, CleanCalendarEvent event) {
    setState(() {
      events[date] = (events[date] ?? [])..add(event);
    });
  }

  void removeEvent(DateTime date, CleanCalendarEvent event) {
    setState(() {
      events[date]!.remove(event);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    selectedEvent = events[selectedDay] ?? [];
    super.initState();
  }

  DateTime? selectedDay;
  List<CleanCalendarEvent>? selectedEvent;

  final Map<DateTime, List<CleanCalendarEvent>> events = {
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      CleanCalendarEvent('Event A',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, 10, 0),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day, 12, 0),
          description: 'A special event',
          color: Colors.blue),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2):
        [
      CleanCalendarEvent('Event B',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 10, 0),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 12, 0),
          color: Colors.orange),
      CleanCalendarEvent('Event C',
          startTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 14, 30),
          endTime: DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day + 2, 17, 0),
          color: Colors.pink),
    ],
  };

  Future<void> uploadEventDataToFirebase(
      Map<DateTime, List<CleanCalendarEvent>> events) async {
    final _database = FirebaseDatabase.instance.reference();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      events.forEach((key, element) {
        for (final event in element) {
          _database.child('user_tables').child(currentUser.uid).push().set({
            'day': key.toString(),
            'summary': event.summary.toString(),
            'startTime': event.startTime.toString(),
            'endTime': event.endTime.toString(),
          });
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
    uploadEventDataToFirebase(events);
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
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
    );
  }
}

void showInputButton({required BuildContext context}) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 200,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Enter event date",
              ),
              onChanged: (date) {
                print("The value entered is : $date");
              },
            ),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter event description",
              ),
              onChanged: (description) {
                print("The value entered is : $description");
              },
            ),
            ElevatedButton(
              child: Text("Add Event"),
              onPressed: () {
                // Get user input from text fields
                // Use the addEvent function to add the new event to the calendar
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text("Remove Event"),
              onPressed: () {
                // Get user input for the event to be removed
                // Use the removeEvent function to remove the event from the calendar
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
