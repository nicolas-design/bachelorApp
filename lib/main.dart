import 'package:flutter/material.dart';
import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'call_log_util.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<EventUsageInfo> events = [];
  Map<String?, UsageInfo?> _usageInfoMap = Map();
  List<String> socialMediaApps = ['instagram', 'facebook', 'snapchat'];

  int standardCount = 4;

  double overallPercentage = 0.0;
  String overallPercentageLabel = "0%";

  double outgoingCallsCount = 0;
  double outgoingCallsPercentage = 0.0;
  String outgoingCallsCountLabel = "0%";

 double totalScreenTimeMinutes = 0;
  double _currentPercentage = 0.0;
  String _percentageLabel = "0%";

  int contactCount = 0;
  double contactPercentage = 0.0;
  String contactCountLabel = "0%";

  bool showDeviceValue = false;  // Controls the visibility
  double deviceValue = 0.0;  
  double deviceValuePercentage = 0.0;
  String deviceValueLabel = "0%";

  double totalSocialMediaTime = 0.0;
  double socialMediaPercentage = 0.0;
  String socialMediaLabel = "0%";

  @override
  void initState() {
    super.initState();

    
  }

  void _showDeviceValueDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Device Value"),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
               setState(() {
                  deviceValue = double.tryParse(_controller.text) ?? 0.0;
                  showDeviceValue = true; // Set this to true to show the device value and indicator
                });
              Navigator.of(context).pop();
              // Handle saving the value here
            },
          ),
        ],
      );
    },
  );
}

  Future<void> initScreenTime() async {
    try {
      UsageStats.grantUsagePermission();

      DateTime endDate = DateTime.now();  // Current moment
      DateTime startDate = endDate.subtract(Duration(days: 1));  // 24 hours ago from now

      

      List<EventUsageInfo> queryEvents = await UsageStats.queryEvents(startDate, endDate);
      List<UsageInfo> t = await UsageStats.queryUsageStats(startDate, endDate);
      

      Map<String?, double> manualAggregatedTimes = {};
      double socialMediaTimeT = 0.0;
     

      for (var i in t) {

        if (double.parse(i.totalTimeInForeground!) > 0) {
          
        
          _usageInfoMap[i.packageName] = i;
          
           DateTime firstTimeStamp = DateTime.fromMillisecondsSinceEpoch(int.parse(i.firstTimeStamp!));
            DateTime lastTimeStamp = DateTime.fromMillisecondsSinceEpoch(int.parse(i.lastTimeStamp!));
            DateTime lastTimeUsed = DateTime.fromMillisecondsSinceEpoch(int.parse(i.lastTimeUsed!));
            double timeInForegroundMinutes = int.parse(i.totalTimeInForeground!) / 1000 / 60;

            print("Package: ${i.packageName}");
            print("First Time Stamp: $firstTimeStamp");
            print("Last Time Stamp: $lastTimeStamp");
            print("Last Time Used: $lastTimeUsed");
            print("Time in Foreground (minutes): $timeInForegroundMinutes");
    

          print('-----\n');
        }
      }
      List<EventUsageInfo> eventsTest = queryEvents.reversed.toList();
      
      for (var event in eventsTest) {
        var usageInfo = _usageInfoMap[event.packageName]; 
        if (usageInfo != null && double.parse(usageInfo.totalTimeInForeground!) > 0) {
          double foregroundTime = double.parse(usageInfo.totalTimeInForeground!);
          if (!manualAggregatedTimes.containsKey(event.packageName)) {
            manualAggregatedTimes[event.packageName] = foregroundTime;
            if (socialMediaApps.any((app) => event.packageName!.toLowerCase().contains(app))) {
            socialMediaTimeT += foregroundTime;
          }
          }
        }
      }


      double totalScreenTime = manualAggregatedTimes.values.fold(0, (previousValue, element) => previousValue + element);

      this.setState(() {
        events = queryEvents.reversed.toList();
        totalScreenTimeMinutes = totalScreenTime / 1000 / 60;
        totalSocialMediaTime = socialMediaTimeT / 1000 / 60;
      });
    } catch (err) {
      print(err);
    }
  }

Future<void> analyzeUsage() async {
  try {
    // Fetching outgoing call count
    int callCount = await CallLogUtil.getOutgoingCallsCount();
    double callPercentage;
    double maxCalls = 4.36;
    double minCalls = 3.35;
    
    initScreenTime();

    if (callCount > maxCalls) {
      callPercentage = 0.0;
    } else if (callCount < minCalls) {
      callPercentage = 1.0;
    } else {
      callPercentage = (maxCalls - callCount) / (maxCalls - minCalls);
    }

    int totalContacts = await CallLogUtil.getContactCount();
    double contactPercentageT;
    double maxContacts = 72.57;
    double minContacts = 56.43;

    if (totalContacts > maxContacts) {
      contactPercentageT = 0.0;
    } else if (totalContacts < minContacts) {
      contactPercentageT = 1.0;
    } else {
      contactPercentageT = (maxContacts - totalContacts) / (maxContacts - minContacts);
    }
  

    double minTime = 127.13;
    double maxTime = 164.0;
    double screenTimePercentage;

    if (totalScreenTimeMinutes <= minTime) {
      screenTimePercentage = 0.0;
    } else if (totalScreenTimeMinutes >= maxTime) {
      screenTimePercentage = 1.0;
    } else {
      screenTimePercentage = (totalScreenTimeMinutes - minTime) / (maxTime - minTime);
    }

    double minSocialMediaTime = 39.55;
    double maxSocialMediaTime = 54.24;
    double socialMediaPercentageT;

    if (totalSocialMediaTime <= minSocialMediaTime) {
      socialMediaPercentageT = 0.0;
    } else if (totalSocialMediaTime >= maxSocialMediaTime) {
      socialMediaPercentageT = 1.0;
    } else {
      socialMediaPercentageT = (totalSocialMediaTime - minSocialMediaTime) / (maxSocialMediaTime - minSocialMediaTime);
    }

    double deviceValuePercentageT = 0.0;
    if (showDeviceValue) {
      standardCount += 1;
      double minDeviceValue = 414.78;
      double maxDeviceValue = 491.94;
      

      if (deviceValue <= minDeviceValue) {
        deviceValuePercentageT = 1.0;
      } else if (deviceValue >= maxDeviceValue) {
        deviceValuePercentageT = 0.0;
      } else {
        deviceValuePercentageT = (maxDeviceValue - deviceValue) / (maxDeviceValue - minDeviceValue);
      }
    }

    
    // Calculate the average of call percentage and screen time percentage
    double averagePercentage = (callPercentage + screenTimePercentage + contactPercentageT + deviceValuePercentageT + socialMediaPercentageT) / standardCount;

    // Update state with new values
    setState(() {
      outgoingCallsCount = callCount.toDouble();
      outgoingCallsPercentage = callPercentage;
      outgoingCallsCountLabel = "${(callPercentage * 100).toStringAsFixed(1)}%";
      _currentPercentage = screenTimePercentage;
      _percentageLabel = "${(screenTimePercentage * 100).toStringAsFixed(1)}%";
      overallPercentage = averagePercentage;
      overallPercentageLabel = "${(averagePercentage * 100).toStringAsFixed(1)}%";
      contactCount = totalContacts;
      contactPercentage = contactPercentageT;
      contactCountLabel = "${(contactPercentage * 100).toStringAsFixed(1)}%";
      deviceValuePercentage = deviceValuePercentageT;
      deviceValueLabel = "${(deviceValuePercentage * 100).toStringAsFixed(1)}%";
      socialMediaPercentage = socialMediaPercentageT;
      socialMediaLabel = "${(socialMediaPercentageT * 100).toStringAsFixed(1)}%";
    });
  } catch (e) {
    print("Error during analysis: $e");
    // Optionally, handle errors, such as by displaying an error message.
  }
}

void _editSocialMediaApps(BuildContext innerContext) {
  showDialog(
    context: innerContext,
    builder: (BuildContext dialogContext) {
      TextEditingController _controller = TextEditingController();

      void addSocialMediaApp() {
        if (_controller.text.isNotEmpty) {
          setState(() {
            socialMediaApps.add(_controller.text.toLowerCase());
            _controller.clear();  // Clear the text field after adding the app
          });
        }
      }

      return AlertDialog(
        title: Text("Edit Social Media Apps"),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: socialMediaApps.length,
                  itemBuilder: (BuildContext itemContext, int index) {
                    return ListTile(
                      title: Text(socialMediaApps[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            socialMediaApps.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: "Add New App",
                ),
                onSubmitted: (String value) {
                  addSocialMediaApp();
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Add'),
            onPressed: addSocialMediaApp,
          ),
          TextButton(
            child: Text('Done'),
            onPressed: () {
              Navigator.of(dialogContext).pop();  // Close the dialog
            },
          ),
        ],
      );
    },
  );
}


 


@override
Widget build(BuildContext context) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text("Usage Stats"),
        actions: [
          IconButton(
            onPressed: UsageStats.grantUsagePermission,
            icon: Icon(Icons.settings),
          )
        ],
      ),
      body: Center(
          child: ListView(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  
                  children: [
                    Text(
                      "Depression Score",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    CircularPercentIndicator(  // Add this widget here
                      
                      radius: 120.0,
                      lineWidth: 13.0,
                      animation: true,
                      percent: overallPercentage,  // This should be dynamic based on your data
                      center: Text(
                        overallPercentageLabel,  // This should also be dynamic
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.green,
                    ),
                    SizedBox(height: 30),  // Space between the circle and the button
                    ElevatedButton(
                      onPressed: () {
                        // Action to perform on button press
                        analyzeUsage();
                      
                        print("Analyze button pressed");
                      },
                      child: Text("Analyze"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,  // Correct property for background color
                        foregroundColor: Colors.white,  // Correct property for text color
                      ),
                    ),
                    SizedBox(height: 50),  // Space between the button and the bottom of the container
                    Text(
                      "Total Screen Time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${totalScreenTimeMinutes.toStringAsFixed(2)} minutes",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 160,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        leading: new Text("> 127 min"),
                        trailing: new Text("164 min <"),
                        percent: _currentPercentage,
                        center: Text(_percentageLabel),
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                      ),
                    ),
                    SizedBox(height: 30),  // Space between the button and the bottom of the container
                    Text(
                      "Total Social Media Time",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${totalSocialMediaTime.toStringAsFixed(2)} minutes",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 200,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        leading: new Text("> 39.55 min"),
                        trailing: new Text("54.24 min <"),
                        percent: socialMediaPercentage,
                        center: Text(socialMediaLabel),
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                      ),
                      
                    ),
                    SizedBox(height: 15),  // Space between the button and the bottom of the container
                     Builder(
                    builder: (BuildContext innerContext) {
                      return OutlinedButton(
                        onPressed: () => _editSocialMediaApps(innerContext),
                        child: Text('Edit'),
                      );
                    }
                  ),
                    SizedBox(height: 30),  // Space between the button and the bottom of the container
                    Text(
                      "Outgoing Calls",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${outgoingCallsCount.toStringAsFixed(2)} calls",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 120,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        leading: new Text("4.36 <"),
                        trailing: new Text("> 3.35"),
                        percent: outgoingCallsPercentage,
                        center: Text(outgoingCallsCountLabel),
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                      ),
                    ),
                    SizedBox(height: 30),  // Space between the button and the bottom of the container
                    Text(
                      "Saved Contacts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${contactCount.toStringAsFixed(2)} contacts",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 140,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        leading: new Text("72.57 <"),
                        trailing: new Text("> 56.43"),
                        percent: contactPercentage,
                        center: Text(contactCountLabel),
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                      ),
                    ),
                     
                    if (showDeviceValue) ...[
                      SizedBox(height: 30),  // Space between the button and the bottom of the container
                      Text(
                        "Device Value",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${deviceValue.toStringAsFixed(2)} €",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 20),
                       Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 180,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 1000,
                        leading: new Text("> 491.94 €"),
                        trailing: new Text("414.78 € <"),
                        percent: deviceValuePercentage,
                        center: Text(deviceValueLabel),
                        barRadius: Radius.circular(10),
                        progressColor: Colors.green,
                      ),
                      
                    ),
                    ],
                    
                  ],
                ),
              ),
              
            ],
          ), 
               
      ),
     floatingActionButton: Builder(
  builder: (context) => FloatingActionButton(
    onPressed: () {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          // Bottom sheet content here
          return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Add Device Value'),
                        onPressed: (){ Navigator.pop(context);
                        _showDeviceValueDialog(context);}
                      ),
                      ElevatedButton(
                        child: const Text('Close'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
        },
      );
    },
    child: Icon(Icons.add),
    backgroundColor: Colors.blue,
  ),
),

    ),
  );
  
}

}









