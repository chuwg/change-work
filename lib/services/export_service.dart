import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shift.dart';
import '../widgets/export_calendar_widget.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

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
          textDirection: TextDirection.ltr,
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
