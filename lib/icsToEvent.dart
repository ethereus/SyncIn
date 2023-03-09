import 'package:flutter/services.dart' show Color, rootBundle;
import 'package:flutter_clean_calendar/clean_calendar_event.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:math' as math;

/* 
CleanCalendarEvent(
  'Event B',
  startTime: DateTime(DateTime.now().year, DateTime.now().month,DateTime.now().day + 2, 10, 0),
  endTime: DateTime(DateTime.now().year, DateTime.now().month,DateTime.now().day + 2, 12, 0),
  color: Colors.orange
  )
*/

List icsToEvent(fileLocation) {
  List events = [];
  // fileLocation needs to be in the format of 'assets/test_data_.ics'
  final icsString = rootBundle.loadString(fileLocation);
  final iCalendar = ICalendar.fromString(icsString as String);
  final iCalJSON = iCalendar.toJson();
  final iCalData = iCalJSON['data'];
  for (final event in iCalData) {
    events.add(CleanCalendarEvent(event['summary'],
        startTime: event['dtstart'],
        endTime: event['dtend'],
        color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
            .withOpacity(1.0)));
  }
  return events;
}
