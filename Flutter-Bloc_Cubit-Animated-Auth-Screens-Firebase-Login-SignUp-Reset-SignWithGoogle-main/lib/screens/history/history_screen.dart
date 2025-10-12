import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';

class HistoryScreen extends StatefulWidget {
  final String deviceName;
  const HistoryScreen({super.key, required this.deviceName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DatabaseReference historyRef;

  @override
  void initState() {
    super.initState();
    historyRef = FirebaseDatabase.instance
        .ref("devices/${widget.deviceName}/readings/history");
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Unknown time';
    try {
      final parsed = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp);
      return DateFormat("d MMM yyyy — h:mm a").format(parsed);
    } catch (e) {
      return timestamp; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.greyGreen,
      appBar: AppBar(
        title: Text(
          "History - ${widget.deviceName}",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            color: ColorsManager.darkBlue,
          ),
        ),
        backgroundColor: ColorsManager.greyGreen,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: StreamBuilder<DatabaseEvent>(
          stream: historyRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: ColorsManager.mainBlue),
              );
            }

            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return Center(
                child: Text(
                  "No history records yet",
                  style: GoogleFonts.nunitoSans(
                    color: ColorsManager.darkBlue,
                    fontSize: 16.sp,
                  ),
                ),
              );
            }

            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final entries = data.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key)); // latest first

            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final record = Map<String, dynamic>.from(entries[index].value);
                final formatted = formatTimestamp(record['timestamp']);

                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🕒 $formatted",
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13.sp,
                            color: ColorsManager.darkBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text("CO₂: ${record['co2']} ppm",
                            style: GoogleFonts.nunitoSans(
                                color: ColorsManager.darkBlue)),
                        Text("Temp: ${record['temperature']} °C",
                            style: GoogleFonts.nunitoSans(
                                color: ColorsManager.darkBlue)),
                        Text("Humidity: ${record['humidity']} %",
                            style: GoogleFonts.nunitoSans(
                                color: ColorsManager.darkBlue)),
                        Text("Dust: ${record['dust']} mg/m³",
                            style: GoogleFonts.nunitoSans(
                                color: ColorsManager.darkBlue)),
                        Text("Air Quality: ${record['airQuality']}",
                            style: GoogleFonts.nunitoSans(
                                color: ColorsManager.darkBlue)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
