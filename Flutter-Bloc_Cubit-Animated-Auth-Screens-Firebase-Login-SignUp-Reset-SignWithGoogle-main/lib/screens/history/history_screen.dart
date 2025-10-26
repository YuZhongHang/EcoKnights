import 'dart:async';
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
  StreamSubscription<DatabaseEvent>? _historySubscription;
  Map<String, List<Map<String, dynamic>>> groupedByDate = {};
  bool _isLoading = true;
  int _totalRecords = 0;

  // Filter state
  String? _selectedDate; // null means "All Dates"
  List<String> _availableDates = [];

  @override
  void initState() {
    super.initState();
    historyRef = FirebaseDatabase.instance
        .ref("devices/${widget.deviceName}/readings/history");
    _listenToHistory();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  void _listenToHistory() {
    _historySubscription = historyRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

        final entries = data.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key)); // newest first

        final List<Map<String, dynamic>> records = entries.map((e) {
          final record = Map<String, dynamic>.from(e.value);
          record['_key'] = e.key; // Store Firebase key for deletion
          return record;
        }).toList();

        // Group records by date
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        final Set<String> dates = {};

        for (var record in records) {
          final timestamp = record['timestamp'] ?? '';
          final date = timestamp.split(' ').first;
          dates.add(date);
          grouped.putIfAbsent(date, () => []).add(record);
        }

        // Sort available dates (newest first)
        final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));

        setState(() {
          groupedByDate = grouped;
          _availableDates = sortedDates;
          _totalRecords = records.length;
          _isLoading = false;
        });
      } else {
        setState(() {
          groupedByDate.clear();
          _availableDates.clear();
          _totalRecords = 0;
          _isLoading = false;
        });
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> get _filteredData {
    if (_selectedDate == null) {
      return groupedByDate;
    }
    return {_selectedDate!: groupedByDate[_selectedDate!] ?? []};
  }

  int get _filteredRecordCount {
    if (_selectedDate == null) {
      return _totalRecords;
    }
    return groupedByDate[_selectedDate!]?.length ?? 0;
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Unknown time';
    try {
      final parsed = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp);
      return DateFormat("h:mm:ss a").format(parsed);
    } catch (e) {
      return timestamp;
    }
  }

  String formatDate(String date) {
    try {
      final parsed = DateFormat("yyyy-MM-dd").parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final parsedDate = DateTime(parsed.year, parsed.month, parsed.day);

      if (parsedDate == today) {
        return "Today - ${DateFormat('MMM dd, yyyy').format(parsed)}";
      } else if (parsedDate == yesterday) {
        return "Yesterday - ${DateFormat('MMM dd, yyyy').format(parsed)}";
      } else {
        return DateFormat('EEEE, MMM dd, yyyy').format(parsed);
      }
    } catch (e) {
      return date;
    }
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.greyGreen,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: ColorsManager.lightYellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: ColorsManager.darkBlue),
                  SizedBox(width: 12.w),
                  Text(
                    'Filter by Date',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.darkBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: ColorsManager.darkBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                children: [
                  // "All Dates" option
                  _buildDateOption(
                    date: null,
                    displayText: 'All Dates',
                    recordCount: _totalRecords,
                  ),
                  const Divider(),
                  // Individual dates
                  ..._availableDates.map((date) {
                    final count = groupedByDate[date]?.length ?? 0;
                    return _buildDateOption(
                      date: date,
                      displayText: formatDate(date),
                      recordCount: count,
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOption({
    required String? date,
    required String displayText,
    required int recordCount,
  }) {
    final isSelected = _selectedDate == date;

    return ListTile(
      leading: Icon(
        date == null ? Icons.view_list : Icons.calendar_today,
        color: isSelected ? ColorsManager.mainBlue : ColorsManager.darkBlue,
      ),
      title: Text(
        displayText,
        style: GoogleFonts.nunitoSans(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? ColorsManager.mainBlue : ColorsManager.darkBlue,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color:
              isSelected ? ColorsManager.mainBlue : ColorsManager.lightYellow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$recordCount',
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : ColorsManager.darkBlue,
          ),
        ),
      ),
      selected: isSelected,
      selectedTileColor: ColorsManager.lightYellow.withOpacity(0.3),
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _deleteRecord(String key, String date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await historyRef.child(key).remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting record: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: Text(
          'Are you sure you want to delete all $_totalRecords records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await historyRef.remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All history cleared successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.greyGreen,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "History - ${widget.deviceName}",
              style: GoogleFonts.nunitoSans(
                fontWeight: FontWeight.bold,
                color: ColorsManager.darkBlue,
                fontSize: 18.sp,
              ),
            ),
            Text(
              _selectedDate == null
                  ? "$_filteredRecordCount records (All Dates)"
                  : "$_filteredRecordCount records",
              style: GoogleFonts.nunitoSans(
                fontSize: 12.sp,
                color: ColorsManager.darkBlue.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: ColorsManager.greyGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: ColorsManager.darkBlue),
                if (_selectedDate != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter by Date',
            onPressed: _showDatePicker,
          ),
          if (_totalRecords > 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: ColorsManager.darkBlue),
              onSelected: (value) {
                if (value == 'clear') {
                  _clearAllHistory();
                } else if (value == 'clear_filter') {
                  setState(() {
                    _selectedDate = null;
                  });
                }
              },
              itemBuilder: (context) => [
                if (_selectedDate != null)
                  PopupMenuItem(
                    value: 'clear_filter',
                    child: Row(
                      children: [
                        const Icon(Icons.clear, color: ColorsManager.mainBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Clear Filter',
                          style: GoogleFonts.nunitoSans(
                              color: ColorsManager.mainBlue),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Clear All History',
                        style: GoogleFonts.nunitoSans(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorsManager.mainBlue),
      );
    }

    if (groupedByDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80.w,
              color: ColorsManager.darkBlue.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              "No history records yet",
              style: GoogleFonts.nunitoSans(
                color: ColorsManager.darkBlue,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Data will be recorded every 30 seconds",
              style: GoogleFonts.nunitoSans(
                color: ColorsManager.darkBlue.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    final filteredData = _filteredData;

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80.w,
              color: ColorsManager.darkBlue.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              "No records for selected date",
              style: GoogleFonts.nunitoSans(
                color: ColorsManager.darkBlue,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
              icon: const Icon(Icons.clear, color: ColorsManager.darkBlue),
              label: const Text(
                'Clear Filter',
                style: TextStyle(
                  color: ColorsManager.darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.zhYellow,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History is auto-updating'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: filteredData.entries.map((dateGroup) {
          final date = dateGroup.key;
          final records = dateGroup.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: ColorsManager.lightYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: ColorsManager.darkBlue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        formatDate(date),
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: ColorsManager.darkBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ColorsManager.mainBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${records.length}",
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              ...records.map((record) {
                final formatted = formatTimestamp(record['timestamp']);
                final key = record['_key'] ?? '';
                return _buildRecordCard(record, formatted, key, date);
              }),
              SizedBox(height: 16.h),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, String formattedTime,
      String key, String date) {
    final co2 = record['co2'] ?? 0;
    final temperature = record['temperature'] ?? 0.0;
    final humidity = record['humidity'] ?? 0.0;
    final dust = record['dust'].toStringAsFixed(2) ?? 0.0;
    final airQuality = record['airQuality'] ?? 'Unknown';

    // Determine air quality color
    Color airQualityColor = Colors.green;
    if (airQuality.toLowerCase().contains('moderate')) {
      airQualityColor = Colors.orange;
    } else if (airQuality.toLowerCase().contains('unhealthy') ||
        airQuality.toLowerCase().contains('poor')) {
      airQualityColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, ColorsManager.gray93Color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.w,
                        color: ColorsManager.mainBlue,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        formattedTime,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14.sp,
                          color: ColorsManager.darkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    iconSize: 20.w,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _deleteRecord(key, date),
                  ),
                ],
              ),
              Divider(
                  height: 16.h, color: ColorsManager.darkBlue.withOpacity(0.2)),
              _buildDataRow(Icons.cloud_outlined, 'CO₂', '$co2 ppm',
                  ColorsManager.mainBlue),
              SizedBox(height: 6.h),
              _buildDataRow(Icons.thermostat_outlined, 'Temperature',
                  '$temperature °C', Colors.orange),
              SizedBox(height: 6.h),
              _buildDataRow(Icons.water_drop_outlined, 'Humidity',
                  '$humidity %', Colors.blue),
              SizedBox(height: 6.h),
              _buildDataRow(Icons.grain, 'Dust', '$dust mg/m³', Colors.brown),
              SizedBox(height: 6.h),
              _buildDataRow(
                  Icons.air, 'Air Quality', airQuality, airQualityColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: color),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 13.sp,
              color: ColorsManager.darkBlue.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunitoSans(
            fontSize: 13.sp,
            color: ColorsManager.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
