import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_calendar/flutter_clean_calendar.dart';


class DemoApp extends StatefulWidget {
  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {

  DateTime selectedDay;
  List <CleanCalendarEvent> selectedEvent;

  final Map<DateTime,List<CleanCalendarEvent>> events = {
    DateTime (DateTime.now().year,DateTime.now().month,DateTime.now().day):
        [
          CleanCalendarEvent('Event A',
          startTime: DateTime(
              DateTime.now().year,DateTime.now().month,DateTime.now().day,10,0),
            endTime:  DateTime(
                DateTime.now().year,DateTime.now().month,DateTime.now().day,12,0),
            description: 'A special event',
            color: Colors.blue[700]),
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

  void _handleData(date){
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
      events[date].remove(event);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    selectedEvent = events[selectedDay] ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        centerTitle: true,
      ),
      body:  SafeArea(
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
            onDateSelected: (date){
              return _handleData(date);
            },
            events: events,
            isExpanded: true,
            dayOfWeekStyle: TextStyle(
              fontSize: 15,
              color: Colors.black12,
              fontWeight: FontWeight.w100,
            ),
            bottomBarTextStyle: TextStyle(
              color: Colors.white,
            ),
            hideBottomBar: false,
            hideArrows: false,
            weekDays: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
          ),
        ),
      ),
    );
  }
}

void showInputButton({BuildContext context}) {
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
            ),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter event description",
              ),
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

//https://pub.dev/packages/icalendar_parser