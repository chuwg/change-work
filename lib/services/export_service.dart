import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/shift.dart';
import '../models/sleep_record.dart';
import '../models/energy_record.dart';
import '../widgets/export_calendar_widget.dart';
import 'database_service.dart';

const _uuid = Uuid();

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  /// Export all data (shifts, sleep, energy) as CSV files and share.
  Future<void> exportAllDataAsCsv() async {
    final db = DatabaseService.instance;
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final files = <XFile>[];

    // Get all shifts (fetch 12 months back)
    final allShifts = <Shift>[];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthShifts =
          await db.getShiftsForMonth(date.year, date.month);
      allShifts.addAll(monthShifts);
    }

    if (allShifts.isNotEmpty) {
      final csv = StringBuffer();
      csv.writeln('날짜,근무유형,시작시간,종료시간,메모');
      for (final s in allShifts) {
        final date = DateFormat('yyyy-MM-dd').format(s.date);
        final type = _shiftTypeLabel(s.type);
        final start = s.startTime ?? '';
        final end = s.endTime ?? '';
        final note = _escapeCsv(s.note ?? '');
        csv.writeln('$date,$type,$start,$end,$note');
      }
      final file = File('${dir.path}/change_shifts_$dateStr.csv');
      await file.writeAsString(csv.toString());
      files.add(XFile(file.path));
    }

    // Export sleep records
    final sleepRecords = await db.getSleepRecords();
    if (sleepRecords.isNotEmpty) {
      final csv = StringBuffer();
      csv.writeln('날짜,취침시간,기상시간,수면시간,품질(1-5),근무유형,출처,메모');
      for (final r in sleepRecords) {
        final date = DateFormat('yyyy-MM-dd').format(r.date);
        final bed = DateFormat('yyyy-MM-dd HH:mm').format(r.bedTime);
        final wake = DateFormat('yyyy-MM-dd HH:mm').format(r.wakeTime);
        final hours = r.durationHours.toStringAsFixed(1);
        final type = r.shiftType ?? '';
        final source = r.source ?? 'manual';
        final note = _escapeCsv(r.note ?? '');
        csv.writeln('$date,$bed,$wake,$hours,${r.quality},$type,$source,$note');
      }
      final file = File('${dir.path}/change_sleep_$dateStr.csv');
      await file.writeAsString(csv.toString());
      files.add(XFile(file.path));
    }

    // Export energy records
    final energyRecords = await db.getEnergyRecords();
    if (energyRecords.isNotEmpty) {
      final csv = StringBuffer();
      csv.writeln('날짜,시간,에너지(1-5),근무유형,활동,기분,메모');
      for (final r in energyRecords) {
        final date = DateFormat('yyyy-MM-dd').format(r.date);
        final time = DateFormat('HH:mm').format(r.timestamp);
        final type = r.shiftType ?? '';
        final activity = r.activity ?? '';
        final mood = r.mood ?? '';
        final note = _escapeCsv(r.note ?? '');
        csv.writeln(
            '$date,$time,${r.energyLevel},$type,$activity,$mood,$note');
      }
      final file = File('${dir.path}/change_energy_$dateStr.csv');
      await file.writeAsString(csv.toString());
      files.add(XFile(file.path));
    }

    if (files.isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: 'Change 앱 데이터 ($dateStr)',
      ),
    );
  }

  /// Pick CSV files and import data. Returns count of imported records per type.
  Future<Map<String, int>> importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return {};

    final counts = {'shifts': 0, 'sleep': 0, 'energy': 0};

    for (final file in result.files) {
      if (file.path == null) continue;
      final content = await File(file.path!).readAsString();
      final filename = file.name.toLowerCase();

      if (filename.contains('shift') || filename.contains('근무')) {
        counts['shifts'] = await _importShiftsCsv(content);
      } else if (filename.contains('sleep') || filename.contains('수면')) {
        counts['sleep'] = await _importSleepCsv(content);
      } else if (filename.contains('energy') || filename.contains('에너지')) {
        counts['energy'] = await _importEnergyCsv(content);
      } else {
        // Detect by header row
        final firstLine = content.split('\n').first;
        if (firstLine.contains('근무유형') && firstLine.contains('시작시간')) {
          counts['shifts'] = await _importShiftsCsv(content);
        } else if (firstLine.contains('취침시간')) {
          counts['sleep'] = await _importSleepCsv(content);
        } else if (firstLine.contains('에너지')) {
          counts['energy'] = await _importEnergyCsv(content);
        }
      }
    }

    return counts;
  }

  Future<int> _importShiftsCsv(String content) async {
    final db = DatabaseService.instance;
    final lines = content.trim().split('\n');
    if (lines.length < 2) return 0;

    // Get existing shift dates to skip duplicates
    final now = DateTime.now();
    final existingShifts = <String>{};
    for (int i = -3; i <= 3; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      final shifts = await db.getShiftsForMonth(date.year, date.month);
      for (final s in shifts) {
        existingShifts.add(DateFormat('yyyy-MM-dd').format(s.date));
      }
    }

    int count = 0;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length < 2) continue;

      try {
        final dateStr = cols[0].trim();
        final typeLabel = cols[1].trim();
        if (existingShifts.contains(dateStr)) continue;

        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final type = _shiftTypeLabelToCode(typeLabel);
        final startTime = cols.length > 2 ? cols[2].trim() : null;
        final endTime = cols.length > 3 ? cols[3].trim() : null;
        final note = cols.length > 4 ? cols[4].trim() : null;

        await db.insertShift(Shift(
          id: _uuid.v4(),
          date: date,
          type: type,
          startTime: startTime?.isEmpty == true ? null : startTime,
          endTime: endTime?.isEmpty == true ? null : endTime,
          note: note?.isEmpty == true ? null : note,
        ));
        count++;
      } catch (_) {}
    }
    return count;
  }

  Future<int> _importSleepCsv(String content) async {
    final db = DatabaseService.instance;
    final lines = content.trim().split('\n');
    if (lines.length < 2) return 0;

    // Get existing sleep dates
    final existing = await db.getSleepRecords(limit: 1000);
    final existingDates = existing
        .map((r) => DateFormat('yyyy-MM-dd').format(r.date))
        .toSet();

    int count = 0;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length < 5) continue;

      try {
        final dateStr = cols[0].trim();
        if (existingDates.contains(dateStr)) continue;

        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final bedTime = DateFormat('yyyy-MM-dd HH:mm').parse(cols[1].trim());
        final wakeTime = DateFormat('yyyy-MM-dd HH:mm').parse(cols[2].trim());
        final quality = int.parse(cols[4].trim()).clamp(1, 5);
        final shiftType = cols.length > 5 ? cols[5].trim() : null;
        final note = cols.length > 7 ? cols[7].trim() : null;

        await db.insertSleepRecord(SleepRecord(
          id: _uuid.v4(),
          date: date,
          bedTime: bedTime,
          wakeTime: wakeTime,
          quality: quality,
          shiftType: shiftType?.isEmpty == true ? null : shiftType,
          note: note?.isEmpty == true ? null : note,
        ));
        count++;
      } catch (_) {}
    }
    return count;
  }

  Future<int> _importEnergyCsv(String content) async {
    final db = DatabaseService.instance;
    final lines = content.trim().split('\n');
    if (lines.length < 2) return 0;

    int count = 0;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length < 3) continue;

      try {
        final dateStr = cols[0].trim();
        final timeStr = cols[1].trim();
        final level = int.parse(cols[2].trim()).clamp(1, 5);
        final shiftType = cols.length > 3 ? cols[3].trim() : null;
        final activity = cols.length > 4 ? cols[4].trim() : null;
        final mood = cols.length > 5 ? cols[5].trim() : null;
        final note = cols.length > 6 ? cols[6].trim() : null;

        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final timeParts = timeStr.split(':');
        final timestamp = DateTime(
          date.year, date.month, date.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]),
        );

        await db.insertEnergyRecord(EnergyRecord(
          id: _uuid.v4(),
          date: date,
          timestamp: timestamp,
          energyLevel: level,
          shiftType: shiftType?.isEmpty == true ? null : shiftType,
          activity: activity?.isEmpty == true ? null : activity,
          mood: mood?.isEmpty == true ? null : mood,
          note: note?.isEmpty == true ? null : note,
          source: 'import',
        ));
        count++;
      } catch (_) {}
    }
    return count;
  }

  /// Parse a single CSV line handling quoted fields
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _shiftTypeLabelToCode(String label) {
    switch (label) {
      case '주간': return 'day';
      case '오후': return 'evening';
      case '야간': return 'night';
      case '휴무': return 'off';
      default: return label; // already in English
    }
  }

  String _shiftTypeLabel(String type) {
    switch (type) {
      case 'day':
        return '주간';
      case 'evening':
        return '오후';
      case 'night':
        return '야간';
      case 'off':
        return '휴무';
      default:
        return type;
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> exportAndShareMonth({
    required int year,
    required int month,
    required Map<DateTime, Shift> shifts,
  }) async {
    final file = await _renderMonthImage(year, month, shifts);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${year}년 ${month}월 근무 스케줄',
      ),
    );
  }

  Future<File> _renderMonthImage(
    int year,
    int month,
    Map<DateTime, Shift> shifts,
  ) async {
    const imageWidth = 1080.0;
    const imageHeight = 1350.0;

    final widget = ExportCalendarWidget(
      year: year,
      month: month,
      shifts: shifts,
    );

    final repaintBoundary = RenderRepaintBoundary();
    final view = ui.PlatformDispatcher.instance.implicitView!;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(
          const Size(imageWidth, imageHeight),
        ),
        logicalConstraints: BoxConstraints.tight(
          const Size(imageWidth, imageHeight),
        ),
        devicePixelRatio: 1.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/change_schedule_${year}_$month.png',
    );
    await file.writeAsBytes(bytes);

    // Clean up
    buildOwner.finalizeTree();

    return file;
  }
}
