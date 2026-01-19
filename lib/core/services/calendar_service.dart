import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_model.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import 'notification_service.dart';

class CalendarService {
  static final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();

  static Future<bool> checkPermissions() async {
    final calendarPermission = await Permission.calendar.request();
    return calendarPermission.isGranted;
  }

  static Future<List<Calendar>> getCalendars() async {
    if (!await checkPermissions()) {
      throw Exception('Calendar permission not granted');
    }

    final calendarsResult = await _deviceCalendar.retrieveCalendars();
    if (calendarsResult.isSuccess) {
      return calendarsResult.data ?? [];
    }
    throw Exception('Failed to retrieve calendars');
  }

  static Future<List<Event>> getUpcomingEvents({int daysAhead = 7}) async {
    if (!await checkPermissions()) {
      throw Exception('Calendar permission not granted');
    }

    final calendars = await getCalendars();
    if (calendars.isEmpty) return [];

    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    final eventsResult = await _deviceCalendar.retrieveEvents(
      calendars.first.id,
      RetrieveEventsParams(
        startDate: now,
        endDate: endDate,
      ),
    );

    if (eventsResult.isSuccess) {
      return eventsResult.data ?? [];
    }
    return [];
  }

  // Check for meetings with contacts in the next 30 minutes
  static Future<void> checkUpcomingMeetings() async {
    try {
      final events = await getUpcomingEvents(daysAhead: 1);
      final now = DateTime.now();

      for (final event in events) {
        if (event.start == null) continue;

        final timeUntilEvent = event.start!.difference(now);
        // Check if event starts in next 30 minutes
        if (timeUntilEvent.inMinutes >= 0 && timeUntilEvent.inMinutes <= 30) {
          await _generatePreMeetingBrief(event);
        }
      }
    } catch (e) {
      print('Error checking upcoming meetings: $e');
    }
  }

  static Future<void> _generatePreMeetingBrief(Event event) async {
    try {
      final user = await SupabaseService.getCurrentUser();
      if (user == null) return;

      // Try to find matching contact by name
      final contacts = await SupabaseService.getContacts(user.id);
      final matchingContact = contacts.firstWhere(
        (c) => event.title?.toLowerCase().contains(c['name'].toLowerCase()) ?? false,
        orElse: () => null,
      );

      if (matchingContact == null) return;

      final contactId = matchingContact['id'];
      final notes = await SupabaseService.getNotes(contactId);
      final lastContactDate = matchingContact['last_contacted_at'];

      final brief = await AIService.generatePreMeetingBrief(
        matchingContact['name'],
        notes,
        lastContactDate,
      );

      // Send notification
      await NotificationService.showLocalNotification(
        'Pre-Meeting Brief: ${matchingContact['name']}',
        brief,
      );
    } catch (e) {
      print('Error generating pre-meeting brief: $e');
    }
  }
}
