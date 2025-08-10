import 'package:aqi_map/aqi_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqi_map/model/api/aqi_info/aqi_info.dart';

Future main() async {
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: AqiApp()));
}

class AqiApp extends StatelessWidget {
  const AqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AqiScreen(),
    );
  }
}

class AqiScreen extends ConsumerWidget {
  const AqiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiInfo = ref.watch(aqiNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: aqiInfo.when(
        data: (data) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              location(data.city.cityName),
              const SizedBox(height: 40),
              aqiValue(data),
              const SizedBox(height: 40),
              aqiDetail(data),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.tealAccent,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget location(String location) {
    return Text(
      location,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w300,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget aqiValue(AqiInfo data) {
    final Color statusColor = _getStatusColor(data.status);

    return Column(
      children: [
        Text(
          data.aqi.toString(),
          style: TextStyle(
            fontSize: 96,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            data.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget aqiDetail(AqiInfo data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          pollutantRow(
              'PM2.5', data.aqiDetail.pm25.value, Colors.orangeAccent),
          pollutantRow(
              'PM10', data.aqiDetail.o3.value, Colors.purpleAccent),
          pollutantRow(
              'NO₂', data.aqiDetail.no2.value, Colors.greenAccent),
          pollutantRow(
              'SO₂', data.aqiDetail.so2.value, Colors.blueAccent),
          pollutantRow('CO', data.aqiDetail.co.value, Colors.redAccent),
        ],
      ),
    );
  }

  Widget pollutantRow(String label, int? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: value ?? 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 40,
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'GOOD':
        return Colors.greenAccent;
      case 'MODERATE':
        return Colors.yellowAccent;
      case 'HAZARDOUS':
        return Colors.orangeAccent;
      case 'UNHEALTHY':
        return Colors.redAccent;
      case 'VERY UNHEALTHY':
        return Colors.purpleAccent;
      case 'SEVERE':
        return Colors.deepPurpleAccent;
      default:
        return Colors.white;
    }
  }
}
