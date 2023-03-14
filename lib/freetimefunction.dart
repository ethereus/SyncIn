import 'package:flutter_clean_calendar/clean_calendar_event.dart';

List findFreeTime(user1, user2, time1, time2) {
  // Grabs all the users events within the time frame given
  List user1Events = getUserTime(user1, time1, time2);
  List user2Events = getUserTime(user2, time1, time2);

  // freeTime will store all the time where the to users are free [[startTime,endTime]]
  List freeTimeList = [];

  int events1Ptr = 0;
  int events2Ptr = 0;

  while (user1Events.length > events1Ptr && user2Events.length > events2Ptr) {
    if (user1Events[events1Ptr].endTime.isBefore(user2Events[events2Ptr].startTime)) {
      // The events do not overlap at all
      events1Ptr++;
    } else if (user2Events[events2Ptr].endTime.isBefore(user1Events[events1Ptr].startTime)) {
      events2Ptr++;
    } else if (user1Events[events1Ptr].startTime.isBefore(user2Events[events2Ptr].startTime) &&
        user1Events[events1Ptr].endTime.isBefore(user2Events[events2Ptr].endTime) &&
        user1Events[events1Ptr].endTime.isAfter(user2Events[events2Ptr].startTime)) {
      // The start of user1Events[events1Ptr] overlaps with user2Events[events2Ptr]
      freeTimeList.add(CleanCalendarEvent("Free Time",
          startTime: user2Events[events2Ptr].startTime,
          endTime: user1Events[events1Ptr].endTime));
      events1Ptr++;
    } else if (user1Events[events1Ptr].startTime.isBefore(user2Events[events2Ptr].endTime) &&
        user1Events[events1Ptr].endTime.isAfter(user2Events[events2Ptr].endTime)) {
      // user1Events[events1Ptr] completely contains user2Events[events2Ptr]
      freeTimeList.add(CleanCalendarEvent("Free Time",
          startTime: user2Events[events2Ptr].startTime,
          endTime: user2Events[events2Ptr].endTime));
      events2Ptr++;
    } else if (user2Events[events2Ptr].startTime.isBefore(user1Events[events1Ptr].startTime) &&
        user2Events[events2Ptr].endTime.isBefore(user1Events[events1Ptr].endTime) &&
        user2Events[events2Ptr].endTime.isAfter(user1Events[events1Ptr].startTime)) {
      // The start of user2Events[events2Ptr] overlaps with user1Events[events1Ptr]
      freeTimeList.add(CleanCalendarEvent("Free Time",
          startTime: user1Events[events1Ptr].startTime,
          endTime: user2Events[events2Ptr].endTime));
      events2Ptr++;
    } else if (user2Events[events2Ptr].startTime.isBefore(user1Events[events1Ptr].endTime) &&
        user2Events[events2Ptr].endTime.isAfter(user1Events[events1Ptr].endTime)) {
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
      if (overlapStart = user1Events[events1Ptr].startTime) {
        events1Ptr++;
      } else if (overlapStart = user2Events[events2Ptr].startTime) {
        events2Ptr++;
      }
    }
  }

  return freeTimeList;
}

List getUserTime(user, time1, time2) {
  /*------------------------------------
  The firebase events pull go here
  --------------------------------------*/
  // ignore: prefer_typing_uninitialized_variables
  var events; //Placeholder for the events pull

  List userEvents = [];

  for (final event in events) {
    //Event is spilt into 2 part [0] being event details and event.startTime being the start time and .endTime being the end time
    if (event.startTime.isAfter(time1) && event.endTime.isBefore(time2)) {
      userEvents.add(event);
    }
  }

  // .sort might need more work but we will see when testing
  userEvents.sort(((a, b) => a.startTime.compareTo(b.startTime)));

  return userEvents;
}
