# SyncIn

**co-ordinating free time between friends**

Welcome to SyncIn,

A calendar app designed for students to make arranging evens easier. SyncIn shows you when your friends are free, and lets you chat with your friends while making plans. You can invite friends into your group via group code and then other members of the group can chat with each other and see when they are free. 

Working features: see when friends are free based on their calendar events, chat to friends through the app, sign in via google.

Currently broken: importing calendar events from .ics files, making created events stay through app close. 

# Important

For this app to work you will need to set up FireBase Authentication to allow Google sign in and a FireBase Realtime Database with the following rules:

``
{ "rules": {
		"group_chat_messages": {
 			".read": true,
 			".write": true,
    },
    "free_time": {
 			".read": true,
 			".write": true,
    }
	}
}
``

And you will need the following permissions in your AndroidManifest.xml file:

``
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
``

You will also need to follow the steps to set up FireBase for your app, and make sure to include the **google-services.json** and **GoogleService-Info.plist** files from your FireBase app project. 

