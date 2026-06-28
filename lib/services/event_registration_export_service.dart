import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../models/event_model.dart';
import '../models/user_model.dart';
import 'file_download_service.dart';

class EventRegistrationExportService {
  String buildCsv({
    required List<ApplicationModel> applications,
    required Map<String, UserModel> volunteers,
  }) {
    final rows = <List<String>>[
      ['Volunteer name', 'Email', 'Phone', 'Status', 'Applied at'],
      ...applications.map((application) {
        final volunteer = volunteers[application.volunteerId];
        return [
          volunteer?.name ?? application.volunteerName,
          volunteer?.email ?? '',
          volunteer?.phone ?? '',
          _statusLabel(application.status),
          DateFormat('yyyy-MM-dd HH:mm').format(application.appliedAt),
        ];
      }),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  Future<String> saveCsv({
    required EventModel event,
    required List<ApplicationModel> applications,
    required Map<String, UserModel> volunteers,
    required String filterLabel,
  }) {
    final csv = buildCsv(applications: applications, volunteers: volunteers);
    final bytes = Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(csv),
    ]);
    return saveDownloadedFile(
      fileName: 'volunteers-${_slug(event.title)}-${_slug(filterLabel)}.csv',
      bytes: bytes,
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  String _csvCell(String value) {
    var safeValue = value;
    if (RegExp(r'^[=+\-@]').hasMatch(safeValue.trimLeft())) {
      safeValue = "'$safeValue";
    }
    return '"${safeValue.replaceAll('"', '""')}"';
  }

  String _statusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'New';
      case ApplicationStatus.reviewing:
        return 'Reviewing';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.waitlisted:
        return 'Waitlisted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  String _slug(String value) {
    final result = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return result.isEmpty ? 'all' : result;
  }
}
