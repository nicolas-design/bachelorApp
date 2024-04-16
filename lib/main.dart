import 'package:flutter/material.dart';
import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:percent_indicator/percent_indicator.dart';

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

  void _updatePercentage() {
  double minTime = 127.13;
  double maxTime = 164.0;
  if (totalScreenTimeMinutes <= minTime) {
    _currentPercentage = 0.0;
  } else if (totalScreenTimeMinutes >= maxTime) {
    _currentPercentage = 1.0;
  } else {
    _currentPercentage = (totalScreenTimeMinutes - minTime) / (maxTime - minTime);
  }
  _percentageLabel = "${(_currentPercentage * 100).toStringAsFixed(1)}%";
  setState(() {});  // Update the UI
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
                    CircularPercentIndicator(  // Add this widget here
                      
                      radius: 120.0,
                      lineWidth: 13.0,
                      animation: true,
                      percent: _currentPercentage,  // This should be dynamic based on your data
                      center: Text(
                        _percentageLabel,  // This should also be dynamic
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.green,
                    ),
                    SizedBox(height: 30),  // Space between the circle and the button
                    ElevatedButton(
                      onPressed: () {
                        // Action to perform on button press
                        _updatePercentage();
                        print("Analyze button pressed");
                      },
                      child: Text("Analyze"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,  // Correct property for background color
                        foregroundColor: Colors.white,  // Correct property for text color
                      ),
                    ),
                    SizedBox(height: 40),  // Space between the button and the bottom of the container
                    
                    Center(
                      child: LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width - 50,
                        animation: true,
                        lineHeight: 20.0,
                        animationDuration: 2500,
                        percent: 0.8,
                        center: Text("80.0%"),
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