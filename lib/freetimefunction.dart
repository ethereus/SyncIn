List findFreeTime(user1, user2, time1, time2) {
  // Grabs all the users events within the time frame given
  List user1Events = getUserTime(user1, time1, time2);
  List user2Events = getUserTime(user2, time1, time2);

  // freeTime will store all the time where the to users are free [[startTime,endTime]]
  List freeTime = [];

  // Variables for the logic of finding free time
  DateTime tempTime = time1;
  var FreeTimeStart = true;
  var temp;

  while (tempTime.isBefore(time2)) {
    //Finds if the user has any events at the given time
    bool user1Free = FreeTime(user1Events, tempTime);
    bool user2Free = FreeTime(user2Events, tempTime);

    // checks if it is start of free time
    if (user1Free && user2Free) {
      if (FreeTimeStart) {
        temp = tempTime;
      }
    }

    // checks if it is end of the free time
    if (!user1Free || !user2Free) {
      if (!FreeTimeStart) {
        freeTime.add([temp, tempTime]);
      }
    }

    // increments the tempTime for every 5 minutes
    tempTime.add(const Duration(minutes: 5));
  }

  return freeTime;
}

List getUserTime(user, time1, time2) {
  /*------------------------------------
  The firebase events pull go here
  --------------------------------------*/
  var Events; //Placeholder for the events pull

  List userEvents = [];

  for (final event in Events) {
    //Event is spilt into 2 part [0] being event details and event[1] being the start time and [2] being the end time
    if (event[1].isAfter(time1) && event[2].isBefore(time2)) {
      userEvents.add(event);
    }
  }

  // .sort might need more work but we will see when testing
  userEvents.sort();

  return userEvents;
}

bool FreeTime(Events, time) {
  for (final event in Events) {
    if (event[1].isAtSameMomentAs(time) ||
        event[2].isAtSameMomentAs(time) ||
        (event[1].isBefore(time) && event[2].isAfter(time))) {
      return false;
    }
  }
  return true;
}
