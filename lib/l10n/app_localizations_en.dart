// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileTitle => 'Profile';

  @override
  String get defaultUserName => 'User';

  @override
  String get statusActive => 'Active';

  @override
  String get roleSystemAdmin => 'System Admin';

  @override
  String get roleSchoolAdmin => 'School Admin';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleStudent => 'Student';

  @override
  String get statPracticesDone => 'Practices Done';

  @override
  String get statAverageScore => 'Average Score';

  @override
  String get statDayStreak => 'Day Streak';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get menuMyResults => 'My Results';

  @override
  String get menuRecordings => 'Recordings';

  @override
  String get menuAppeals => 'Appeals & Re-evaluation';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String get menuLogOut => 'Log Out';

  @override
  String get profileLoadError => 'Could not load profile information.';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get navHome => 'Home';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingLateNight => 'Late night session?';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeContinueLearning => 'Continue with';

  @override
  String get homeExamsToComplete => 'Exams To Complete';

  @override
  String get homeNoExamsLeft => 'No exams left to complete';

  @override
  String get homeNoDateSet => 'No date set';

  @override
  String get homeNotCompleted => 'Not completed';

  @override
  String get homeSearchLessons => 'Search lessons…';

  @override
  String get homeResume => 'Resume →';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsGroupNew => 'New';

  @override
  String get notificationsGroupEarlier => 'Earlier';

  @override
  String get scheduleTitle => 'Your Schedules';

  @override
  String scheduleLoadError(String error) {
    return 'Could not load your schedule.\n$error';
  }

  @override
  String get scheduleRetry => 'Retry';

  @override
  String scheduleToday(String date) {
    return 'Today · $date';
  }

  @override
  String get scheduleNoSessionsToday => 'No sessions today.';

  @override
  String scheduleTomorrow(String date) {
    return 'Tomorrow · $date';
  }

  @override
  String get scheduleNoSessionsTomorrow => 'No sessions tomorrow.';

  @override
  String get scheduleKindCentralized => 'Centralized';

  @override
  String get scheduleKindClassTest => 'Class Test';

  @override
  String get scheduleTimeUnset => '--:--';

  @override
  String get scheduleJumpToday => 'Today';

  @override
  String get scheduleLegendHasSession => 'Has a scheduled session';

  @override
  String scheduleRoomLabel(String room) {
    return 'Room $room';
  }

  @override
  String get scheduleStatusOpen => 'Open';

  @override
  String get scheduleStatusUpcoming => 'Upcoming';

  @override
  String get scheduleStatusClosed => 'Closed';

  @override
  String get teacherExamClassTestsTab => 'Class Tests';

  @override
  String get teacherExamCentralizedTab => 'Centralized';

  @override
  String get teacherExamKindClassTest => 'Class Test';

  @override
  String get teacherExamCentralizedSection => 'Centralized Exams';

  @override
  String get teacherExamNoClassTests => 'No class tests yet.';

  @override
  String get teacherExamNoCentralizedExams =>
      'No centralized exams assigned to you.';

  @override
  String get teacherExamStatusDraft => 'Draft';

  @override
  String get teacherExamStatusScheduled => 'Scheduled';

  @override
  String get teacherExamStatusInProgress => 'In Progress';

  @override
  String get teacherExamStatusClosed => 'Closed';

  @override
  String get teacherExamStatusResultsPublished => 'Results Published';

  @override
  String get teacherExamStatusCancelled => 'Cancelled';

  @override
  String get teacherExamActionSchedule => 'Schedule';

  @override
  String get teacherExamActionCancel => 'Cancel';

  @override
  String get teacherExamActionStart => 'Start';

  @override
  String get teacherExamActionClose => 'Close';

  @override
  String get teacherExamActionPublishResults => 'Publish Results';

  @override
  String get classTestUpdateStatusError => 'Could not update status.';

  @override
  String get classTestDeleteTitle => 'Delete class test?';

  @override
  String classTestDeleteBody(String name) {
    return 'This will remove \"$name\" permanently.';
  }

  @override
  String get classTestCancel => 'Cancel';

  @override
  String get classTestDelete => 'Delete';

  @override
  String get classTestDeleteError => 'Could not delete class test.';

  @override
  String get classTestOpens => 'Opens';

  @override
  String get classTestCloses => 'Closes';

  @override
  String get classTestNotSet => 'Not set';

  @override
  String get classTestActions => 'Actions';

  @override
  String get classTestNameRequired => 'Name is required.';

  @override
  String get classTestSelectClass => 'Select a class.';

  @override
  String get classTestSelectQuestion => 'Select at least one question.';

  @override
  String get classTestSaveError => 'Could not save the class test.';

  @override
  String get classTestEditTitle => 'Edit Class Test';

  @override
  String get classTestNewTitle => 'New Class Test';

  @override
  String get classTestNameLabel => 'Name';

  @override
  String get classTestDescriptionLabel => 'Description';

  @override
  String get classTestClassLabel => 'Class';

  @override
  String get classTestOpensAt => 'Opens at';

  @override
  String get classTestClosesAt => 'Closes at';

  @override
  String get classTestQuestions => 'Questions';

  @override
  String classTestQuestionsSelected(int count) {
    return '$count selected';
  }

  @override
  String get classTestSaveButton => 'Save';

  @override
  String get classTestCreateButton => 'Create Class Test';

  @override
  String get centralizedExamBlueprint => 'Blueprint';

  @override
  String get centralizedExamMembers => 'Members';

  @override
  String get centralizedExamNoMembers => 'No members assigned.';

  @override
  String get questionPickerLoadError => 'Could not load questions.';

  @override
  String get questionPickerTitle => 'Select Questions';

  @override
  String questionPickerDone(int count) {
    return 'Done ($count)';
  }

  @override
  String get questionPickerSearchHint => 'Search questions';
}
