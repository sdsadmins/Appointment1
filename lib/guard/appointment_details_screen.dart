import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../action/action.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  
  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic>? appointmentData;
  Map<String, dynamic>? detailedAppointmentData;
  bool isLoading = true;
  String? errorMessage;
  
  // Loading states for admit/reject operations
  Map<int, bool> admitLoading = {}; // Track loading state per user index
  Map<int, bool> rejectLoading = {}; // Track loading state per user index
  bool admitAllLoading = false;
  bool rejectAllLoading = false;
  bool admitPartialLoading = false;
  
  // Helper to check if any operation is in progress
  bool get isAnyOperationLoading {
    return admitAllLoading || 
           rejectAllLoading || 
           admitPartialLoading ||
           admitLoading.values.any((loading) => loading) ||
           rejectLoading.values.any((loading) => loading);
  }


  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final result = await ActionService.getAppointmentById(widget.appointmentId);
      
      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
        });
        
        // Load detailed appointment data for scheduled date, time, and venue
        try {
          final detailedResult = await ActionService.getAppointmentByIdDetailed(widget.appointmentId);
          print('DEBUG: Detailed result success: ${detailedResult['success']}');
          print('DEBUG: Detailed result keys: ${detailedResult.keys}');
          
          if (detailedResult['success'] && detailedResult['data'] != null) {
            final data = detailedResult['data'];
            print('DEBUG: Detailed data type: ${data.runtimeType}');
            print('DEBUG: Detailed data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');
            print('DEBUG: Full detailed data: $data');
            
            if (data is Map<String, dynamic>) {
              print('DEBUG: Has scheduledDateTime: ${data.containsKey('scheduledDateTime')}');
              print('DEBUG: scheduledDateTime value: ${data['scheduledDateTime']}');
              print('DEBUG: scheduledDateTime type: ${data['scheduledDateTime']?.runtimeType}');
              
              // Print all keys to see what's available
              print('DEBUG: All available keys in detailed data:');
              data.keys.forEach((key) {
                print('  - $key: ${data[key]?.runtimeType}');
              });
            }
            
            setState(() {
              detailedAppointmentData = data;
              isLoading = false;
            });
          } else {
            print('DEBUG: Detailed result failed: ${detailedResult['message']}');
            print('DEBUG: Detailed result statusCode: ${detailedResult['statusCode']}');
            setState(() {
              isLoading = false;
            });
          }
        } catch (detailedError) {
          print('DEBUG: Error loading detailed data: $detailedError');
          print('DEBUG: Error stack trace: ${StackTrace.current}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load appointment details: $e';
        isLoading = false;
      });
    }
  }



  // Helper methods for check-in status display
  String _getMainStatusText() {
    if (appointmentData == null) return 'Status not available';
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return 'Admitted';
      case 'checked_in_partial':
        return 'Partially Admitted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Admission';
      case 'not_arrived':
        return 'Not Arrived';
      default:
        return 'Not Arrived';
    }
  }

  Color _getMainStatusColor() {
    if (appointmentData == null) return Colors.grey;
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return Colors.green;
      case 'checked_in_partial':
        return Colors.lightGreen;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'not_arrived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getMainStatusIcon() {
    if (appointmentData == null) return Icons.info_outline;
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return Icons.check_circle;
      case 'checked_in_partial':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending_actions;
      case 'not_arrived':
        return Icons.schedule;
      default:
        return Icons.schedule;
    }
  }

  String _getUserStatusText(String status) {
    switch (status?.toString().toLowerCase()) {
      case 'checked_in':
        return 'Admitted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      case 'not_arrived':
        return 'Not Arrived';
      default:
        return 'Not Arrived';
    }
  }

  Color _getUserStatusColor(String status) {
    switch (status?.toString().toLowerCase()) {
      case 'checked_in':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'not_arrived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatScheduledDate() {
    if (detailedAppointmentData == null || detailedAppointmentData!['scheduledDateTime'] == null) return 'N/A';
    
    try {
      final scheduledData = detailedAppointmentData!['scheduledDateTime'] as Map<String, dynamic>;
      final dateStr = scheduledData['date'];
      
      if (dateStr == null) return 'N/A';
      
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      print('DEBUG: Error formatting scheduled date: $e');
      return 'N/A';
    }
  }

  /// Change: time is now formatted in 12-hour format with AM/PM suffix
  String _formatScheduledTime() {
    if (detailedAppointmentData == null || detailedAppointmentData!['scheduledDateTime'] == null) return 'N/A';
    
    try {
      final scheduledData = detailedAppointmentData!['scheduledDateTime'] as Map<String, dynamic>;
      final timeStr = scheduledData['time'];
      if (timeStr == null || timeStr == '') return 'N/A';

      // Parse the HH:mm string and reformat into 12 hour with AM/PM
      final parts = timeStr.split(":");
      if (parts.length != 2) return timeStr;
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      String ampm = (hour >= 12) ? "PM" : "AM";
      int hour12 = hour % 12 == 0 ? 12 : hour % 12;
      String formattedTime = "${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm";
      return formattedTime;
    } catch (e) {
      print('DEBUG: Error formatting scheduled time: $e');
      return 'N/A';
    }
  }

  String _getScheduledVenue() {
    if (detailedAppointmentData == null) return 'N/A';
    try {
      // Prefer top-level venueLabel (from detailed API)
      final topLevel = detailedAppointmentData!['venueLabel']?.toString();
      if (topLevel != null && topLevel.isNotEmpty) return topLevel;
      final scheduledData = detailedAppointmentData!['scheduledDateTime'];
      if (scheduledData is Map<String, dynamic>) {
        final venueLabel = scheduledData['venueLabel']?.toString();
        return venueLabel ?? 'N/A';
      }
    } catch (e) {
      print('DEBUG: Error getting scheduled venue: $e');
    }
    return 'N/A';
  }

  /// Guard-facing display names for sub-venues.
  ///
  /// DISPLAY ONLY — the raw backend value is never modified and is never sent
  /// back to the API, so the rename is local to this screen. Other roles and
  /// the web portal continue to see the original names. "Badri Darshan" is
  /// deliberately absent: it is shown unchanged.
  static const Map<String, String> _subvenueDisplayAliases = {
    'gurudev meeting room': 'Vyasa',
    'lounge darshan': 'Atri',
  };

  /// Collapses every encoding of a sub-venue to a single lookup key, e.g.
  /// 'Gurudev Meeting Room', 'gurudev_meeting_room' and
  /// 'morning-gurudev_meeting_room' all become 'gurudev meeting room'.
  String _normalizeSubvenueKey(String raw) {
    var key = raw.trim().toLowerCase();
    key = key.replaceAll(RegExp(r'[_\-]+'), ' '); // unify separators
    key = key.replaceAll(RegExp(r'\s+'), ' ').trim(); // collapse whitespace
    key = key.replaceFirst(
      RegExp(r'^(morning|afternoon|evening|night)\s+'),
      '',
    ); // strip the session prefix used by the web app
    return key.trim();
  }

  /// Returns the guard-facing label for a sub-venue, or the original value when
  /// there is no alias for it.
  String _displaySubvenue(String raw) {
    if (raw.trim().isEmpty) return '';
    return _subvenueDisplayAliases[_normalizeSubvenueKey(raw)] ?? raw.trim();
  }

  String _getSubvenue() {
    if (detailedAppointmentData == null) return '';
    try {
      final topLevel = detailedAppointmentData!['subvenue']?.toString();
      if (topLevel != null && topLevel.isNotEmpty) return _displaySubvenue(topLevel);
      final scheduledData = detailedAppointmentData!['scheduledDateTime'];
      if (scheduledData is Map<String, dynamic>) {
        final subvenue = scheduledData['subvenue']?.toString();
        return _displaySubvenue(subvenue ?? '');
      }
    } catch (_) {}
    return '';
  }

  // Determine if this appointment is marked as external (E badge)
  bool _isExternalAppointment() {
    try {
      if (detailedAppointmentData == null) return false;
      if (detailedAppointmentData!['isExternal'] == true) return true;
      final scheduled = detailedAppointmentData!['scheduledDateTime'];
      if (scheduled is Map<String, dynamic>) {
        return scheduled['isExternal'] == true;
      }
    } catch (_) {}
    return false;
  }

  // Determine if this appointment is private (P badge)
  bool _isPrivateAppointment() {
    try {
      if (detailedAppointmentData == null) return false;
      if (detailedAppointmentData!['isPrivate'] == true) return true;
      final scheduled = detailedAppointmentData!['scheduledDateTime'];
      if (scheduled is Map<String, dynamic>) {
        return scheduled['isPrivate'] == true;
      }
    } catch (_) {}
    return false;
  }

  // Secretary enabled "Allow with car" when scheduling ("Allow car" badge)
  bool _isCarAllowed() {
    try {
      if (detailedAppointmentData == null) return false;
      final scheduled = detailedAppointmentData!['scheduledDateTime'];
      if (scheduled is Map<String, dynamic>) {
        return scheduled['allowWithCar'] == true;
      }
    } catch (_) {}
    return false;
  }

  // Secretary initials for badge using detailed appointment data
  String _getSecretaryInitials() {
    if (detailedAppointmentData == null) return '—';

    // Try assignedSecretary.fullName first
    final assignedSecretary = detailedAppointmentData!['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      final fullName = assignedSecretary['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return _initialsFromName(fullName);
      }
    }

    // Try scheduledBy when populated as object (e.g. { _id, fullName })
    final scheduledBy = detailedAppointmentData!['scheduledBy'];
    if (scheduledBy is Map<String, dynamic>) {
      final fullName = scheduledBy['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return _initialsFromName(fullName);
      }
    }

    // Fallback to other secretary fields if present
    final secretaryName =
        detailedAppointmentData!['secretaryName']?.toString() ??
        detailedAppointmentData!['assignedTo']?.toString() ??
        detailedAppointmentData!['secretary']?.toString();

    if (secretaryName != null && secretaryName.isNotEmpty) {
      return _initialsFromName(secretaryName);
    }
    return '—';
  }

  String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '—';
  }

  Widget _buildBadgeCircle({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  bool _isQuickAppointment() {
    if (detailedAppointmentData == null) return false;
    final apptType = detailedAppointmentData!['appt_type']?.toString();
    final quickApt = detailedAppointmentData!['quick_apt'];
    return apptType == 'quick' && 
           quickApt is Map<String, dynamic> && 
           quickApt['isQuickAppointment'] == true;
  }

  bool _isGuestAppointment() {
    if (detailedAppointmentData == null) return false;
    final appointmentType = detailedAppointmentData!['appointmentType']?.toString();
    final guestInformation = detailedAppointmentData!['guestInformation'];
    return appointmentType?.toLowerCase() == 'guest' ||
        (guestInformation is Map<String, dynamic> &&
            guestInformation['fullName']?.toString().isNotEmpty == true);
  }

  /// Designation of the main appointee, resolved with the same precedence the
  /// secretary view uses (see appointment_detail_page.dart `_getAppointmentRole`):
  /// guest -> quick appointment -> the user's current designation.
  ///
  /// These fields live on `detailedAppointmentData` (GET /appointment/{id});
  /// the check-in payload backing `appointmentData` does not carry them.
  String _getMainAppointeeDesignation() {
    if (detailedAppointmentData == null) return '';
    try {
      final data = detailedAppointmentData!;

      if (_isGuestAppointment()) {
        final guestInformation = data['guestInformation'];
        if (guestInformation is Map<String, dynamic>) {
          final designation = guestInformation['designation']?.toString();
          if (designation != null && designation.trim().isNotEmpty) {
            return designation.trim();
          }
        }
      }

      final quickApt = data['quick_apt'];
      if (data['appt_type']?.toString() == 'quick' && quickApt is Map<String, dynamic>) {
        final required = quickApt['required'];
        if (required is Map<String, dynamic>) {
          final designation = required['designation']?.toString();
          if (designation != null && designation.trim().isNotEmpty) {
            return designation.trim();
          }
        }
      }

      final current = data['userCurrentDesignation']?.toString();
      if (current != null && current.trim().isNotEmpty) return current.trim();
    } catch (e) {
      print('DEBUG: Error resolving main appointee designation: $e');
    }
    return '';
  }

  /// Company / organization of the main appointee. Same precedence as
  /// [_getMainAppointeeDesignation].
  ///
  /// Note: quick appointments (created via "Add Appointment") currently have no
  /// company field on the document at all, so this returns '' for them and the
  /// row is hidden. The `quick_apt.required` lookup below is forward-compatible
  /// and will start working with no further mobile changes once the backend
  /// persists a company for quick appointments.
  String _getMainAppointeeCompany() {
    if (detailedAppointmentData == null) return '';
    try {
      final data = detailedAppointmentData!;

      if (_isGuestAppointment()) {
        final guestInformation = data['guestInformation'];
        if (guestInformation is Map<String, dynamic>) {
          final company = guestInformation['company']?.toString();
          if (company != null && company.trim().isNotEmpty) {
            return company.trim();
          }
        }
      }

      final quickApt = data['quick_apt'];
      if (data['appt_type']?.toString() == 'quick' && quickApt is Map<String, dynamic>) {
        final required = quickApt['required'];
        if (required is Map<String, dynamic>) {
          final company = (required['company'] ??
                  required['organization'] ??
                  required['companyName'])
              ?.toString();
          if (company != null && company.trim().isNotEmpty) {
            return company.trim();
          }
        }
      }

      final current = data['userCurrentCompany']?.toString();
      if (current != null && current.trim().isNotEmpty) return current.trim();
    } catch (e) {
      print('DEBUG: Error resolving main appointee company: $e');
    }
    return '';
  }

  /// Name + designation + company as one copyable block, one per line.
  /// Blank fields are skipped so no empty lines end up on the clipboard.
  String _buildMainAppointeeCopyText(String fullName) {
    final designation = _getMainAppointeeDesignation();
    final company = _getMainAppointeeCompany();
    final lines = <String>[
      if (fullName.trim().isNotEmpty && fullName.trim() != 'Unknown') fullName.trim(),
      if (designation.isNotEmpty) designation,
      if (company.isNotEmpty) company,
    ];
    return lines.join('\n');
  }

  int _getTotalNumberOfUsers() {
    try {
      // Check if this is a quick appointment
      if (_isQuickAppointment() && appointmentData != null) {
        // For quick appointments, use totalUsers from checkInStatus first
        if (appointmentData!['totalUsers'] != null) {
          final total = int.tryParse(appointmentData!['totalUsers'].toString()) ?? 0;
          if (total > 0) {
            return total;
          }
        }
        // Fallback to numberOfPeople in quick_apt.optional
        final quickApt = detailedAppointmentData!['quick_apt'];
        if (quickApt is Map<String, dynamic>) {
          final optional = quickApt['optional'];
          if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
            final numberOfPeople = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
            if (numberOfPeople > 0) {
              return numberOfPeople;
            }
          }
        }
      }

      // Prefer top-level totalUsers when available (used for large groups)
      if (appointmentData != null && appointmentData!['totalUsers'] != null) {
        final total = int.tryParse(appointmentData!['totalUsers'].toString()) ?? 0;
        if (total > 0) {
          return total;
        }
      }

      if (detailedAppointmentData != null) {
        // Try to get numberOfUsers from accompanyUsers
        final accompanyUsers = detailedAppointmentData!['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final numberOfUsers = accompanyUsers['numberOfUsers'];
          if (numberOfUsers != null) {
            final result = int.tryParse(numberOfUsers.toString()) ?? 0;
            // Add 1 for the main user (total = main user + accompanying users)
            if (result > 0) {
              return result + 1;
            }
          }
        }

        // Fallback: try direct numberOfUsers field
        final directNumberOfUsers = detailedAppointmentData!['numberOfUsers'];
        if (directNumberOfUsers != null) {
          final result = int.tryParse(directNumberOfUsers.toString()) ?? 0;
          if (result > 0) {
            return result;
          }
        }
      }

      // Final fallback: count users from the appointmentData (check-in status data)
      if (appointmentData != null && appointmentData!['users'] != null) {
        final usersList = appointmentData!['users'] as List<dynamic>;
        return usersList.length;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatPhoneNumber(dynamic phoneData) {
    if (phoneData == null) return 'N/A';
    try {
      final countryCode = phoneData['countryCode'] ?? '';
      final number = phoneData['number'] ?? '';
      if (countryCode.isEmpty && number.isEmpty) return 'N/A';
      return '$countryCode$number';
    } catch (e) {
      return 'N/A';
    }
  }

  bool _hasPendingUsers() {
    if (appointmentData == null) return false;
    // If backend provides aggregate totals (large group), use them to decide
    final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
    final checkedInUsers = int.tryParse(appointmentData!['checkedInUsers']?.toString() ?? '') ?? 0;
    final usersList = (appointmentData!['users'] as List<dynamic>?) ?? const [];

    if (totalUsers > usersList.length) {
      // Large group: pending if not all checked in
      return checkedInUsers < totalUsers;
    }

    // Normal case: derive from individual users
    return usersList.any((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
    });
  }

  int _getTotalUsers() {
    if (appointmentData == null) return 0;
    
    // Check if this is a quick appointment
    if (_isQuickAppointment()) {
      // For quick appointments, use totalUsers from checkInStatus first
      final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
      if (totalUsers > 0) {
        return totalUsers;
      }
      // Fallback to numberOfPeople in quick_apt.optional
      if (detailedAppointmentData != null) {
        final quickApt = detailedAppointmentData!['quick_apt'];
        if (quickApt is Map<String, dynamic>) {
          final optional = quickApt['optional'];
          if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
            final numberOfPeople = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
            if (numberOfPeople > 0) {
              return numberOfPeople;
            }
          }
        }
      }
    }
    
    final usersList = (appointmentData!['users'] as List<dynamic>?) ?? [];
    final actualTotalUsers = usersList.length;
    final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
    
    // If total users from backend is more than 10, use backend totalUsers
    if (totalUsers > 10) {
      return totalUsers;
    }
    
    // If users are 10 or less, use users array length
    if (actualTotalUsers <= 10) {
      return actualTotalUsers;
    }
    
    // Fallback to users array length
    return actualTotalUsers;
  }

  int _getAdmittedUsers() {
    if (appointmentData == null) return 0;
    
    final usersList = (appointmentData!['users'] as List<dynamic>?) ?? [];
    final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
    final checkedInUsers = int.tryParse(appointmentData!['checkedInUsers']?.toString() ?? '') ?? 0;
    
    // For quick appointments, always use checkedInUsers directly
    // (users array only has main user, so we can't count from array)
    if (_isQuickAppointment()) {
      return checkedInUsers;
    }
    
    // If total users from backend is more than 10, use checkedInUsers directly
    if (totalUsers > 10) {
      return checkedInUsers;
    }
    
    // For 10 or fewer users, count individual users from users array
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'checked_in';
    }).length;
  }

  int _getRejectedUsers() {
    if (appointmentData == null) return 0;
    
    final usersList = (appointmentData!['users'] as List<dynamic>?) ?? [];
    final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
    
    // If total users from backend is more than 10, count rejected users from users array only
    if (totalUsers > 10) {
      return usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
    }
    
    // For 10 or fewer users, count individual users from users array
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'rejected';
    }).length;
  }

  int _getNotArrivedUsers() {
    if (appointmentData == null) return 0;
    
    final usersList = (appointmentData!['users'] as List<dynamic>?) ?? [];
    final totalUsers = int.tryParse(appointmentData!['totalUsers']?.toString() ?? '') ?? 0;
    final checkedInUsers = int.tryParse(appointmentData!['checkedInUsers']?.toString() ?? '') ?? 0;
    
    // For quick appointments, calculate not arrived as total - admitted - rejected
    // (users array only has main user, so we calculate from totals)
    if (_isQuickAppointment()) {
      final rejectedCount = usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
      return totalUsers - checkedInUsers - rejectedCount;
    }
    
    // If total users from backend is more than 10, calculate not arrived as total - admitted - rejected
    if (totalUsers > 10) {
      final rejectedCount = usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
      return totalUsers - checkedInUsers - rejectedCount;
    }
    
    // For 10 or fewer users, count individual users from users array
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
    }).length;
  }

  Widget _buildCountItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _calculateMainStatus(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 'not_arrived';

    int checkedInCount = 0;
    int rejectedCount = 0;
    final expectedTotal = _getTotalNumberOfUsers();
    final observedTotal = users.length;

    for (final user in users) {
      final status = user['status']?.toString().toLowerCase();
      if (status == 'checked_in') {
        checkedInCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      }
    }

    // If we only have partial user list (large group), use partial logic
    if (expectedTotal > observedTotal) {
      if (checkedInCount > 0) return 'checked_in_partial';
      if (rejectedCount > 0) return 'checked_in_partial';
      return 'not_arrived';
    }

    // Full list logic
    if (checkedInCount == expectedTotal && expectedTotal > 0) {
      return 'checked_in';
    }
    if (rejectedCount == expectedTotal && expectedTotal > 0) {
      return 'rejected';
    }
    if (checkedInCount == 0 && rejectedCount == 0) {
      return 'not_arrived';
    }
    return 'checked_in_partial';
  }



  // Admit/Reject functionality
  Future<void> _admitUser(int index) async {
    if (appointmentData == null || isAnyOperationLoading) return;

    setState(() {
      admitLoading[index] = true;
    });

    try {
      final updatedUsers = List<Map<String, dynamic>>.from(appointmentData!['users']);
      
      // Use index-based matching instead of userId
      if (index >= 0 && index < updatedUsers.length) {
        final user = updatedUsers[index];
        updatedUsers[index] = {
          ...user,
          'status': 'checked_in',
          'checkedInAt': DateTime.now().toIso8601String(),
        };

        final mainStatus = _calculateMainStatus(updatedUsers);

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: mainStatus,
          users: updatedUsers,
          totalUsers: _getTotalNumberOfUsers(),
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
            admitLoading[index] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${user['fullName']} admitted successfully'),
            backgroundColor: Colors.green,
          ));
        } else {
          setState(() {
            admitLoading[index] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message'] ?? 'Failed to admit user'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      setState(() {
        admitLoading[index] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }


  Future<void> _rejectUser(int index) async {
    if (appointmentData == null || isAnyOperationLoading) return;

    setState(() {
      rejectLoading[index] = true;
    });

    try {
      final updatedUsers = List<Map<String, dynamic>>.from(appointmentData!['users']);
      
      // Use index-based matching instead of userId
      if (index >= 0 && index < updatedUsers.length) {
        final user = updatedUsers[index];
        updatedUsers[index] = {
          ...user,
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
        };

        final mainStatus = _calculateMainStatus(updatedUsers);

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: mainStatus,
          users: updatedUsers,
          totalUsers: _getTotalNumberOfUsers(),
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
            rejectLoading[index] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${user['fullName']} rejected successfully'),
            backgroundColor: Colors.orange,
          ));
        } else {
          setState(() {
            rejectLoading[index] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message'] ?? 'Failed to reject user'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      setState(() {
        rejectLoading[index] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _admitAllUsers() async {
  if (appointmentData == null || isAnyOperationLoading) return;

  setState(() {
    admitAllLoading = true;
  });

  try {
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    final totalUsersCount = _getTotalNumberOfUsers();
    final isLargeGroup = totalUsersCount > 10;

    if (isLargeGroup) {
      // For large groups, only main user is present in array; send directive with totalUsers
      final mainUser = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : <String, dynamic>{};
      final updatedMainUser = {
        ...mainUser,
        'status': 'checked_in',
        'checkedInAt': DateTime.now().toIso8601String(),
      };

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: appointmentData!['_id'],
        mainStatus: 'checked_in',
        users: [updatedMainUser],
        totalUsers: totalUsersCount,
      );

      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
          admitAllLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All $totalUsersCount users admitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          admitAllLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to admit all users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Small group: process entire list
      final updatedUsers = usersList.map<Map<String, dynamic>>((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        return {
          ...userMap,
          'status': 'checked_in',
          'checkedInAt': DateTime.now().toIso8601String(),
        };
      }).toList();

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: appointmentData!['_id'],
        mainStatus: 'checked_in',
        users: updatedUsers, // Pass the entire updated users array here
      );

      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
          admitAllLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All users admitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          admitAllLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to admit all users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    setState(() {
      admitAllLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<void> _rejectAllUsers() async {
    if (appointmentData == null || isAnyOperationLoading) return;

    setState(() {
      rejectAllLoading = true;
    });

    try {
      final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
      final totalUsersCount = _getTotalNumberOfUsers();
      final isLargeGroup = totalUsersCount > 10;

      if (isLargeGroup) {
        final mainUser = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : <String, dynamic>{};
        final updatedMainUser = {
          ...mainUser,
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
        };

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: 'rejected',
          users: [updatedMainUser],
          totalUsers: totalUsersCount,
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
            rejectAllLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All $totalUsersCount users rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            rejectAllLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to reject all users'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final updatedUsers = usersList.map<Map<String, dynamic>>((user) {
          final Map<String, dynamic> userMap = user as Map<String, dynamic>;
          return {
            ...userMap,
            'status': 'rejected',
            'rejectedAt': DateTime.now().toIso8601String(),
          };
        }).toList();

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: 'rejected',
          users: updatedUsers,
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
            rejectAllLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All users rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            rejectAllLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to reject all users'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        rejectAllLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _admitPartialUsers(int partialUsersCount) async {
    if (appointmentData == null || isAnyOperationLoading) return;

    setState(() {
      admitPartialLoading = true;
    });

    try {
      final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
      final totalUsersCount = _getTotalNumberOfUsers();

      // For large groups, update main user and send partialUsersCount
      final mainUser = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : <String, dynamic>{};
      final updatedMainUser = {
        ...mainUser,
        'status': 'checked_in_partial',
        'checkedInAt': DateTime.now().toIso8601String(),
      };

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: appointmentData!['_id'],
        mainStatus: 'checked_in_partial',
        users: [updatedMainUser],
        totalUsers: totalUsersCount,
        partialUsersCount: partialUsersCount,
      );

      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
          admitPartialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$partialUsersCount users partially admitted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          admitPartialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to partially admit users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        admitPartialLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageModal(String imageUrl, String userName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            onDoubleTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 200,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Copies [text] to the clipboard, following the same snackbar contract used
  /// in lib/components/inbox/appointment_detail_page.dart (green floating on
  /// success, red on failure). The payload here is multi-line, so we show a
  /// short label instead of echoing the copied text back.
  Future<void> _copyToClipboard(String text, {String label = 'Details'}) async {
    if (text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nothing to copy'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shared pill used for the MAIN APPOINTEE / SECRETARY ADDED / VIP / No Photo
  /// tags on a user card.
  Widget _buildTagPill({
    required String label,
    required Color background,
    required Color border,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// A "Designation: Chief Secretary" style row. Callers must skip empty values.
  Widget _buildAppointeeInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showPartialAdmissionDialog() {
    if (isAnyOperationLoading) return; // Don't show dialog if any operation is in progress
    
    final TextEditingController countController = TextEditingController();
    final totalUsers = _getTotalNumberOfUsers();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Partial Admission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many users from the total $totalUsers would you like to admit?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of users to admit',
                  hintText: 'Enter count',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final count = int.tryParse(countController.text);
                if (count != null && count > 0 && count <= totalUsers) {
                  Navigator.of(context).pop();
                  _admitPartialUsers(count);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid number between 1 and $totalUsers'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Admit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final String fullName = (user['fullName'] ?? 'Unknown').toString();
    final userType = user['userType'] ?? 'unknown';
    final status = user['status'] ?? 'unknown';
    final String? profilePhotoUrl = user['profilePhotoUrl']?.toString();
    final totalUsers = _getTotalNumberOfUsers();
    final isAccompanyingUserWithoutPhoto = userType != 'main' && profilePhotoUrl == null && totalUsers > 10;
    final isNewUser = user['adminStatus'] == true || user['adminStatus'] == 'true';
    final isVip = user['type']?.toString().toLowerCase() == 'vip';

    // Designation / company are only available for the main appointee — the
    // accompanying-person records carry no such fields anywhere in the API.
    final isMainAppointee = index == 0;
    final mainDesignation = isMainAppointee ? _getMainAppointeeDesignation() : '';
    final mainCompany = isMainAppointee ? _getMainAppointeeCompany() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getUserStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First line: Index, name, tags and — for the main appointee —
          // designation, company and a copy-to-clipboard button.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. $fullName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Tags — a Wrap so any combination reflows onto a new
                    // line instead of overflowing on narrow screens.
                    if (isMainAppointee ||
                        isNewUser ||
                        isVip ||
                        isAccompanyingUserWithoutPhoto) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (isMainAppointee)
                            _buildTagPill(
                              label: 'MAIN APPOINTEE',
                              background: const Color(0xFFFFF7ED),
                              border: const Color(0xFFFDBA74),
                              textColor: const Color(0xFFC2410C),
                              icon: Icons.star_rounded,
                            ),
                          if (isNewUser)
                            _buildTagPill(
                              label: 'SECRETARY ADDED',
                              background: Colors.blue.shade50,
                              border: Colors.blue.shade200,
                              textColor: Colors.blue.shade700,
                            ),
                          if (isVip)
                            _buildTagPill(
                              label: 'VIP',
                              background: Colors.purple.shade50,
                              border: Colors.purple.shade200,
                              textColor: Colors.purple.shade700,
                            ),
                          if (isAccompanyingUserWithoutPhoto)
                            _buildTagPill(
                              label: 'No Photo',
                              background: Colors.orange.withOpacity(0.1),
                              border: Colors.orange.withOpacity(0.3),
                              textColor: Colors.orange.shade700,
                              icon: Icons.info_outline,
                            ),
                        ],
                      ),
                    ],

                    // Designation / Company — main appointee only. Empty
                    // values are hidden entirely rather than shown as 'N/A'.
                    if (mainDesignation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildAppointeeInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Designation',
                        value: mainDesignation,
                      ),
                    ],
                    if (mainCompany.isNotEmpty) ...[
                      SizedBox(height: mainDesignation.isNotEmpty ? 6 : 8),
                      _buildAppointeeInfoRow(
                        icon: Icons.apartment_outlined,
                        label: 'Company / Organization',
                        value: mainCompany,
                      ),
                    ],
                  ],
                ),
              ),

              // Copy name + designation + company as one block
              if (isMainAppointee) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Copy name, designation & company',
                  onPressed: () => _copyToClipboard(
                    _buildMainAppointeeCopyText(fullName),
                    label: 'Appointee details',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  color: const Color(0xFFF97316),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  splashRadius: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          // Second line: Profile Image - Instagram Style
          AspectRatio(
            aspectRatio: 1.0, // Square aspect ratio like Instagram
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: profilePhotoUrl != null
                    // Tapping anywhere on the photo opens the full-screen
                    // viewer. (The old corner zoom button has been removed.)
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showImageModal(profilePhotoUrl, fullName),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[900],
                          child: Image.network(
                            profilePhotoUrl,
                            fit: BoxFit.cover, // Cover the entire square area
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Image unavailable',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAccompanyingUserWithoutPhoto 
                                ? 'Photo not required\nfor groups > 10'
                                : 'No profile photo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isAccompanyingUserWithoutPhoto) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Photo required for verification',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Third line: Action buttons or status display
          if (status == 'checked_in') ...[
            // Show checked in status instead of buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Admitted',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'rejected') ...[
            // Show rejected status instead of buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rejected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show action buttons for non-admitted users
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isAnyOperationLoading ? null : () => _admitUser(index),
                    icon: admitLoading[index] == true
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(admitLoading[index] == true ? 'Processing...' : 'Admit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isAnyOperationLoading ? null : () => _rejectUser(index),
                    icon: rejectLoading[index] == true
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.close, size: 16),
                    label: Text(rejectLoading[index] == true ? 'Processing...' : 'Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316), // Orange
                Color(0xFFEAB308), // Yellow
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAppointmentDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appointment ID Card with Scheduled Details
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEAB308)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: badges column — External (E), Private (P), Secretary initials
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isExternalAppointment()) ...[
                                      _buildBadgeCircle(
                                        label: 'E',
                                        bgColor: Colors.white,
                                        borderColor: Colors.white,
                                        textColor: const Color(0xFFF97316),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    if (_isPrivateAppointment()) ...[
                                      _buildBadgeCircle(
                                        label: 'P',
                                        bgColor: Colors.red,
                                        borderColor: Colors.white,
                                        textColor: Colors.white,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    _buildBadgeCircle(
                                      label: _getSecretaryInitials(),
                                      bgColor: Colors.lightBlue.shade100,
                                      borderColor: Colors.white,
                                      textColor: Colors.blue.shade800,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Appointment ID: ${appointmentData?['appointmentId'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatScheduledDate(),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatScheduledTime(),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getScheduledVenue(),
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (_getSubvenue().isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.95),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _getSubvenue(),
                                                      style: const TextStyle(
                                                        color: Color(0xFFF97316),
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          // "Allow car" badge — secretary allowed this
                                          // appointment to come with a car
                                          if (_isCarAllowed())
                                            // Side-view white car with "Allow car" on its body
                                            SizedBox(
                                              width: 120,
                                              height: 64,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  const FaIcon(
                                                    FontAwesomeIcons.carSide,
                                                    color: Colors.white,
                                                    size: 64,
                                                  ),
                                                  Positioned(
                                                    bottom: 18,
                                                    child: Text(
                                                      'Allow car',
                                                      style: TextStyle(
                                                        color: Colors.amber.shade700,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (_getTotalNumberOfUsers() > 10) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.people,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Total Users: ${_getTotalUsers()}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Removed Total Number of Users Card
                      const SizedBox(height: 0),

                      // Show completion message when all users are processed (moved above count)
                      if (!_hasPendingUsers()) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'All users have been processed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Photo Policy Information Banner (show when total users > 10)
                      if (_getTotalNumberOfUsers() > 10) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Photo Policy for Large Groups',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'For groups with more than 10 people, only the main appointee\'s photo is required. Accompanying users are identified by name and other details.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // User Count Summary (always visible)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCountItem('Total', _getTotalUsers(), Icons.people, Colors.blue),
                            _buildCountItem('Admitted', _getAdmittedUsers(), Icons.check_circle, Colors.green),
                            _buildCountItem('Rejected', _getRejectedUsers(), Icons.cancel, Colors.red),
                            _buildCountItem('Not Arrived', _getNotArrivedUsers(), Icons.schedule, Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Action Buttons (only show when there are pending users)
                      if (_hasPendingUsers()) ...[
                        // Check if this is a quick appointment
                        if (_isQuickAppointment()) ...[
                          // For quick appointments, always show Partially Admit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isAnyOperationLoading ? null : _showPartialAdmissionDialog,
                              icon: admitPartialLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(admitPartialLoading ? 'Processing...' : 'Partially Admit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ] else if (_getTotalNumberOfUsers() > 10) ...[
                          // For large groups (>10 users), show Partially Admitted button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isAnyOperationLoading ? null : _showPartialAdmissionDialog,
                              icon: admitPartialLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(admitPartialLoading ? 'Processing...' : 'Partially Admitted'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ] else ...[
                          // For small groups (≤10 users), show Admit All and Reject All buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isAnyOperationLoading ? null : _admitAllUsers,
                                  icon: admitAllLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(admitAllLoading ? 'Processing...' : 'Admit All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isAnyOperationLoading ? null : _rejectAllUsers,
                                  icon: rejectAllLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.cancel),
                                  label: Text(rejectAllLoading ? 'Processing...' : 'Reject All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAnyOperationLoading ? Colors.grey : Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),

                      // User Cards
                      if (appointmentData?['users'] != null) ...[
                        ...appointmentData!['users'].asMap().entries.map<Widget>((entry) => 
                          _buildUserCard(entry.value, entry.key)
                        ).toList(),
                      ],
                    ],
                  ),
                ),
    );
  }
} 