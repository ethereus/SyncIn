// ignore: file_names
import 'package:flutter/services.dart';
import 'package:flutter_clean_calendar/clean_calendar_event.dart';

List findUSerFreeTime(user) {
  //Server call to grab events of user goes here
  // ignore: unused_local_variable
  List events = []; // Placeholder
  events
      .sort(); //Might need to override the compare function of cleanCalendarEvent
  DateTime freeStartTime =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  List freeTime = [];
  DateTime freeEndTime;
  for (int i = 0; i < events.length; i++) {
    freeEndTime = events[i].startTime;
    freeTime.add(CleanCalendarEvent("Free Time",
        startTime: freeStartTime,
        endTime: freeEndTime,
        color: const Color.fromARGB(0, 30, 255, 0)));
    freeStartTime = events[i].endTime;
  }

  return freeTime;
}
