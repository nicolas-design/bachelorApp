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

  double overallPercentage = 0.0;
  String overallPercentageLabel = "0%";

  double outgoingCallsCount = 0;
  double outgoingCallsPercentage = 0.0;
  String outgoingCallsCountLabel = "0%";

 double totalScreenTimeMinutes = 0;
  double _currentPercentage = 0.0;
  String _percentageLabel = "0%";

  @override
  void initState() {
    super.initState();

    initUsage();
  }

  Future<void> initUsage() async {
    try {
      UsageStats.grantUsagePermission();

      DateTime endDate = new DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: 1));
      

      List<EventUsageInfo> queryEvents = await UsageStats.queryEvents(startDate, endDate);
      List<UsageInfo> t = await UsageStats.queryUsageStats(startDate, endDate);
      

      Map<String?, double> manualAggregatedTimes = {};
     

      for (var i in t) {

        if (double.parse(i.totalTimeInForeground!) > 0) {
        
          _usageInfoMap[i.packageName] = i;
          
          print(
              DateTime.fromMillisecondsSinceEpoch(int.parse(i.firstTimeStamp!))
                  .toIso8601String());

          print(DateTime.fromMillisecondsSinceEpoch(int.parse(i.lastTimeStamp!))
              .toIso8601String());

          print(i.packageName);
          print(DateTime.fromMillisecondsSinceEpoch(int.parse(i.lastTimeUsed!))
              .toIso8601String());
          print(int.parse(i.totalTimeInForeground!) / 1000 / 60);

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
          }
        }
      }


      double totalScreenTime = manualAggregatedTimes.values.fold(0, (previousValue, element) => previousValue + element);

      this.setState(() {
        events = queryEvents.reversed.toList();
        totalScreenTimeMinutes = totalScreenTime / 1000 / 60;
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

    if (callCount > maxCalls) {
      callPercentage = 0.0;
    } else if (callCount < minCalls) {
      callPercentage = 1.0;
    } else {
      callPercentage = (maxCalls - callCount) / (maxCalls - minCalls);
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

    // Calculate the average of call percentage and screen time percentage
    double averagePercentage = (callPercentage + screenTimePercentage) / 2;

    // Update state with new values
    setState(() {
      outgoingCallsCount = callCount.toDouble();
      outgoingCallsPercentage = callPercentage;
      outgoingCallsCountLabel = "${(callPercentage * 100).toStringAsFixed(1)}%";
      _currentPercentage = screenTimePercentage;
      _percentageLabel = "${(screenTimePercentage * 100).toStringAsFixed(1)}%";
      overallPercentage = averagePercentage;
      overallPercentageLabel = "${(averagePercentage * 100).toStringAsFixed(1)}%";
    });
  } catch (e) {
    print("Error during analysis: $e");
    // Optionally, handle errors, such as by displaying an error message.
  }
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
        child: RefreshIndicator(
          onRefresh: initUsage,
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
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    ),
  );
}


}