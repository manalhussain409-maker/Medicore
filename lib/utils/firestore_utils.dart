import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely parses Firestore Timestamp, ISO strings, or DateTime values.
DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

DateTime parseFirestoreDateOrNow(dynamic value) {
  return parseFirestoreDate(value) ?? DateTime.now();
}
