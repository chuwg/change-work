import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../utils/constants.dart';

class ShiftTimesScreen extends StatefulWidget {
  const ShiftTimesScreen({super.key});

  @override
  State<ShiftTimesScreen> createState() => _ShiftTimesScreenState();
}

class _ShiftTimesScreenState extends State<ShiftTimesScreen> {
  late Map<String, Map<String, String>> _shiftTimes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.customShiftTimesKey);
    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      _shiftTimes = decoded.map((k, v) =>
          MapEntry(k, Map<String, String>.from(v as Map)));
    } else {
      _shiftTimes = Map.from(AppConstants.defaultShiftTimes)
          .map((k, v) => MapEntry(k, Map<String, String>.from(v)));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.customShiftTimesKey, jsonEncode(_shiftTimes));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('근무 시간이 저장되었습니다')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.customShiftTimesKey);
    setState(() {
      _shiftTimes = Map.from(AppConstants.defaultShiftTimes)
          .map((k, v) => MapEntry(k, Map<String, String>.from(v)));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기본값으로 초기화되었습니다')),
      );
    }
  }

  Future<void> _pickTime(String shiftType, String field) async {
    final current = _shiftTimes[shiftType]![field]!;
    final parts = current.split(':');
    final initialTime =
        TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surfaceDarkElevated,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _shiftTimes[shiftType]![field] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 시간 설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveTimes,
            child: const Text('저장',
                style: TextStyle(color: AppTheme.primary, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '각 근무 타입의 시작/종료 시간을 설정하세요.\n건강 가이드가 이 시간을 기준으로 계산됩니다.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildShiftCard(
                  '주간 근무',
                  'day',
                  Icons.wb_sunny_rounded,
                  AppTheme.shiftDay,
                ),
                const SizedBox(height: 12),
                _buildShiftCard(
                  '저녁 근무',
                  'evening',
                  Icons.wb_twilight_rounded,
                  AppTheme.shiftEvening,
                ),
                const SizedBox(height: 12),
                _buildShiftCard(
                  '야간 근무',
                  'night',
                  Icons.nightlight_rounded,
                  AppTheme.shiftNight,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('기본값으로 초기화'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShiftCard(
      String title, String type, IconData icon, Color color) {
    final times = _shiftTimes[type]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeTile(
                  '시작',
                  times['start']!,
                  () => _pickTime(type, 'start'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.textTertiary, size: 18),
              ),
              Expanded(
                child: _buildTimeTile(
                  '종료',
                  times['end']!,
                  () => _pickTime(type, 'end'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
