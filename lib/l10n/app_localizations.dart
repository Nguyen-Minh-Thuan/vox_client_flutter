import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @roleSystemAdmin.
  ///
  /// In en, this message translates to:
  /// **'System Admin'**
  String get roleSystemAdmin;

  /// No description provided for @roleSchoolAdmin.
  ///
  /// In en, this message translates to:
  /// **'School Admin'**
  String get roleSchoolAdmin;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @statPracticesDone.
  ///
  /// In en, this message translates to:
  /// **'Practices Done'**
  String get statPracticesDone;

  /// No description provided for @statAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get statAverageScore;

  /// No description provided for @statDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get statDayStreak;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sectionSettings;

  /// No description provided for @menuMyResults.
  ///
  /// In en, this message translates to:
  /// **'My Results'**
  String get menuMyResults;

  /// No description provided for @menuRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get menuRecordings;

  /// No description provided for @menuAppeals.
  ///
  /// In en, this message translates to:
  /// **'Appeals & Re-evaluation'**
  String get menuAppeals;

  /// No description provided for @menuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// No description provided for @menuNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get menuNotifications;

  /// No description provided for @menuLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get menuLogOut;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile information.'**
  String get profileLoadError;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingLateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night session?'**
  String get greetingLateNight;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @homeContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue with'**
  String get homeContinueLearning;

  /// No description provided for @homeExamsToComplete.
  ///
  /// In en, this message translates to:
  /// **'Exams To Complete'**
  String get homeExamsToComplete;

  /// No description provided for @homeNoExamsLeft.
  ///
  /// In en, this message translates to:
  /// **'No exams left to complete'**
  String get homeNoExamsLeft;

  /// No description provided for @homeNoDateSet.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get homeNoDateSet;

  /// No description provided for @homeNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get homeNotCompleted;

  /// No description provided for @homeSearchLessons.
  ///
  /// In en, this message translates to:
  /// **'Search lessons…'**
  String get homeSearchLessons;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume →'**
  String get homeResume;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsGroupNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get notificationsGroupNew;

  /// No description provided for @notificationsGroupEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsGroupEarlier;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Schedules'**
  String get scheduleTitle;

  /// No description provided for @scheduleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your schedule.\n{error}'**
  String scheduleLoadError(String error);

  /// No description provided for @scheduleRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scheduleRetry;

  /// No description provided for @scheduleToday.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String scheduleToday(String date);

  /// No description provided for @scheduleNoSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'No sessions today.'**
  String get scheduleNoSessionsToday;

  /// No description provided for @scheduleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow · {date}'**
  String scheduleTomorrow(String date);

  /// No description provided for @scheduleNoSessionsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'No sessions tomorrow.'**
  String get scheduleNoSessionsTomorrow;

  /// No description provided for @scheduleKindCentralized.
  ///
  /// In en, this message translates to:
  /// **'Centralized'**
  String get scheduleKindCentralized;

  /// No description provided for @scheduleKindClassTest.
  ///
  /// In en, this message translates to:
  /// **'Class Test'**
  String get scheduleKindClassTest;

  /// No description provided for @scheduleTimeUnset.
  ///
  /// In en, this message translates to:
  /// **'--:--'**
  String get scheduleTimeUnset;

  /// No description provided for @scheduleJumpToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleJumpToday;

  /// No description provided for @scheduleLegendHasSession.
  ///
  /// In en, this message translates to:
  /// **'Has a scheduled session'**
  String get scheduleLegendHasSession;

  /// No description provided for @scheduleRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {room}'**
  String scheduleRoomLabel(String room);

  /// No description provided for @scheduleStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get scheduleStatusOpen;

  /// No description provided for @scheduleStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get scheduleStatusUpcoming;

  /// No description provided for @scheduleStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get scheduleStatusClosed;

  /// No description provided for @teacherExamClassTestsTab.
  ///
  /// In en, this message translates to:
  /// **'Class Tests'**
  String get teacherExamClassTestsTab;

  /// No description provided for @teacherExamCentralizedTab.
  ///
  /// In en, this message translates to:
  /// **'Centralized'**
  String get teacherExamCentralizedTab;

  /// No description provided for @teacherExamKindClassTest.
  ///
  /// In en, this message translates to:
  /// **'Class Test'**
  String get teacherExamKindClassTest;

  /// No description provided for @teacherExamCentralizedSection.
  ///
  /// In en, this message translates to:
  /// **'Centralized Exams'**
  String get teacherExamCentralizedSection;

  /// No description provided for @teacherExamNoClassTests.
  ///
  /// In en, this message translates to:
  /// **'No class tests yet.'**
  String get teacherExamNoClassTests;

  /// No description provided for @teacherExamNoCentralizedExams.
  ///
  /// In en, this message translates to:
  /// **'No centralized exams assigned to you.'**
  String get teacherExamNoCentralizedExams;

  /// No description provided for @teacherExamStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherExamStatusDraft;

  /// No description provided for @teacherExamStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get teacherExamStatusScheduled;

  /// No description provided for @teacherExamStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get teacherExamStatusInProgress;

  /// No description provided for @teacherExamStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get teacherExamStatusClosed;

  /// No description provided for @teacherExamStatusResultsPublished.
  ///
  /// In en, this message translates to:
  /// **'Results Published'**
  String get teacherExamStatusResultsPublished;

  /// No description provided for @teacherExamStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get teacherExamStatusCancelled;

  /// No description provided for @teacherExamActionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get teacherExamActionSchedule;

  /// No description provided for @teacherExamActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get teacherExamActionCancel;

  /// No description provided for @teacherExamActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get teacherExamActionStart;

  /// No description provided for @teacherExamActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get teacherExamActionClose;

  /// No description provided for @teacherExamActionPublishResults.
  ///
  /// In en, this message translates to:
  /// **'Publish Results'**
  String get teacherExamActionPublishResults;

  /// No description provided for @classTestUpdateStatusError.
  ///
  /// In en, this message translates to:
  /// **'Could not update status.'**
  String get classTestUpdateStatusError;

  /// No description provided for @classTestDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete class test?'**
  String get classTestDeleteTitle;

  /// No description provided for @classTestDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{name}\" permanently.'**
  String classTestDeleteBody(String name);

  /// No description provided for @classTestCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get classTestCancel;

  /// No description provided for @classTestDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get classTestDelete;

  /// No description provided for @classTestDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete class test.'**
  String get classTestDeleteError;

  /// No description provided for @classTestOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get classTestOpens;

  /// No description provided for @classTestCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get classTestCloses;

  /// No description provided for @classTestNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get classTestNotSet;

  /// No description provided for @classTestActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get classTestActions;

  /// No description provided for @classTestNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get classTestNameRequired;

  /// No description provided for @classTestSelectClass.
  ///
  /// In en, this message translates to:
  /// **'Select a class.'**
  String get classTestSelectClass;

  /// No description provided for @classTestSelectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Select at least one question.'**
  String get classTestSelectQuestion;

  /// No description provided for @classTestSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the class test.'**
  String get classTestSaveError;

  /// No description provided for @classTestEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Class Test'**
  String get classTestEditTitle;

  /// No description provided for @classTestNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Class Test'**
  String get classTestNewTitle;

  /// No description provided for @classTestNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get classTestNameLabel;

  /// No description provided for @classTestDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get classTestDescriptionLabel;

  /// No description provided for @classTestClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classTestClassLabel;

  /// No description provided for @classTestOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens at'**
  String get classTestOpensAt;

  /// No description provided for @classTestClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes at'**
  String get classTestClosesAt;

  /// No description provided for @classTestQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get classTestQuestions;

  /// No description provided for @classTestQuestionsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String classTestQuestionsSelected(int count);

  /// No description provided for @classTestSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get classTestSaveButton;

  /// No description provided for @classTestCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Class Test'**
  String get classTestCreateButton;

  /// No description provided for @centralizedExamBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Blueprint'**
  String get centralizedExamBlueprint;

  /// No description provided for @centralizedExamMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get centralizedExamMembers;

  /// No description provided for @centralizedExamNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members assigned.'**
  String get centralizedExamNoMembers;

  /// No description provided for @questionPickerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions.'**
  String get questionPickerLoadError;

  /// No description provided for @questionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Questions'**
  String get questionPickerTitle;

  /// No description provided for @questionPickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String questionPickerDone(int count);

  /// No description provided for @questionPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions'**
  String get questionPickerSearchHint;

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @pzRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get pzRetry;

  /// No description provided for @pzLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load personalized practice.'**
  String get pzLoadError;

  /// No description provided for @pzSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get pzSeeAll;

  /// No description provided for @pzMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String pzMinutes(int count);

  /// No description provided for @pzLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get pzLevelBeginner;

  /// No description provided for @pzLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get pzLevelIntermediate;

  /// No description provided for @pzLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get pzLevelAdvanced;

  /// No description provided for @pzHomeSessionToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SESSION'**
  String get pzHomeSessionToday;

  /// No description provided for @pzHomePersonalizedBadge.
  ///
  /// In en, this message translates to:
  /// **'PERSONALIZED'**
  String get pzHomePersonalizedBadge;

  /// No description provided for @pzHomeSessionMeta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · 1-on-1 conversation · focus:'**
  String pzHomeSessionMeta(int minutes);

  /// No description provided for @pzHomeStartSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Start speaking'**
  String get pzHomeStartSpeaking;

  /// No description provided for @pzHomeChangeTopic.
  ///
  /// In en, this message translates to:
  /// **'Change topic'**
  String get pzHomeChangeTopic;

  /// No description provided for @pzHomeStatSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions done'**
  String get pzHomeStatSessions;

  /// No description provided for @pzHomeStatAverage.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get pzHomeStatAverage;

  /// No description provided for @pzHomeStatWeeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get pzHomeStatWeeklyGoal;

  /// No description provided for @pzHomeWeeklyFocus.
  ///
  /// In en, this message translates to:
  /// **'This week\'s focus'**
  String get pzHomeWeeklyFocus;

  /// No description provided for @pzHomeViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get pzHomeViewProfile;

  /// No description provided for @pzHomeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get pzHomeSuggestions;

  /// No description provided for @pzTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking topics'**
  String get pzTopicsTitle;

  /// No description provided for @pzTopicsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics, skills…'**
  String get pzTopicsSearchHint;

  /// No description provided for @pzTopicsFilterForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get pzTopicsFilterForYou;

  /// No description provided for @pzTopicsFilterByGoal.
  ///
  /// In en, this message translates to:
  /// **'By goal'**
  String get pzTopicsFilterByGoal;

  /// No description provided for @pzTopicsFilterByWeakness.
  ///
  /// In en, this message translates to:
  /// **'Weak spots'**
  String get pzTopicsFilterByWeakness;

  /// No description provided for @pzTopicsFilterSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get pzTopicsFilterSaved;

  /// No description provided for @pzTopicsPriority.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY #1'**
  String get pzTopicsPriority;

  /// No description provided for @pzTopicsMatch.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String pzTopicsMatch(int percent);

  /// No description provided for @pzTopicsSpeakThis.
  ///
  /// In en, this message translates to:
  /// **'Speak this topic'**
  String get pzTopicsSpeakThis;

  /// No description provided for @pzTopicsOtherSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Other suggestions'**
  String get pzTopicsOtherSuggestions;

  /// No description provided for @pzTopicsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topics in this list yet.'**
  String get pzTopicsEmpty;

  /// No description provided for @pzTopicsFooterTip.
  ///
  /// In en, this message translates to:
  /// **'This list updates after every session — based on the topics you get excited about and the mistakes that keep coming back.'**
  String get pzTopicsFooterTip;

  /// No description provided for @pzTopicsWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get pzTopicsWhy;

  /// No description provided for @pzSessionLive.
  ///
  /// In en, this message translates to:
  /// **'Speaking · {time}'**
  String pzSessionLive(String time);

  /// No description provided for @pzSessionCorrectNow.
  ///
  /// In en, this message translates to:
  /// **'FIX NOW · {count} POINTS'**
  String pzSessionCorrectNow(int count);

  /// No description provided for @pzSessionKnownWeakness.
  ///
  /// In en, this message translates to:
  /// **'Known weak spot · time #{count}'**
  String pzSessionKnownWeakness(int count);

  /// No description provided for @pzSessionHearCorrect.
  ///
  /// In en, this message translates to:
  /// **'Hear it right'**
  String get pzSessionHearCorrect;

  /// No description provided for @pzSessionSayAgain.
  ///
  /// In en, this message translates to:
  /// **'Say it again'**
  String get pzSessionSayAgain;

  /// No description provided for @pzSessionRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording your answer…'**
  String get pzSessionRecording;

  /// No description provided for @pzSessionTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to answer'**
  String get pzSessionTapToSpeak;

  /// No description provided for @pzSessionThinking.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get pzSessionThinking;

  /// No description provided for @pzSessionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get pzSessionFinish;

  /// No description provided for @pzSessionMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record your answer.'**
  String get pzSessionMicDenied;

  /// No description provided for @pzSessionRecordError.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. Please try again.'**
  String get pzSessionRecordError;

  /// No description provided for @pzSessionExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this session?'**
  String get pzSessionExitTitle;

  /// No description provided for @pzSessionExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this session will not be saved.'**
  String get pzSessionExitBody;

  /// No description provided for @pzSessionExitStay.
  ///
  /// In en, this message translates to:
  /// **'Keep speaking'**
  String get pzSessionExitStay;

  /// No description provided for @pzSessionExitLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get pzSessionExitLeave;

  /// No description provided for @pzSessionPlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No recording available yet.'**
  String get pzSessionPlaybackUnavailable;

  /// No description provided for @pzSessionNoSampleAudio.
  ///
  /// In en, this message translates to:
  /// **'No model audio for this sentence yet.'**
  String get pzSessionNoSampleAudio;

  /// No description provided for @pzSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get pzSummaryTitle;

  /// No description provided for @pzSummaryHeader.
  ///
  /// In en, this message translates to:
  /// **'{topic} · {minutes} MIN'**
  String pzSummaryHeader(String topic, int minutes);

  /// No description provided for @pzSummaryDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs last session'**
  String pzSummaryDelta(String delta);

  /// No description provided for @pzSummaryRubric.
  ///
  /// In en, this message translates to:
  /// **'Rubric · 5 criteria'**
  String get pzSummaryRubric;

  /// No description provided for @pzSummaryRubricLegend.
  ///
  /// In en, this message translates to:
  /// **'weight · score /10'**
  String get pzSummaryRubricLegend;

  /// No description provided for @pzSummaryRepeatedErrors.
  ///
  /// In en, this message translates to:
  /// **'Repeated mistakes this session'**
  String get pzSummaryRepeatedErrors;

  /// No description provided for @pzSummaryDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill these {count} mistakes · {minutes} min'**
  String pzSummaryDrill(int count, int minutes);

  /// No description provided for @pzSummaryReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay my recording'**
  String get pzSummaryReplay;

  /// No description provided for @pzWeaknessTitle.
  ///
  /// In en, this message translates to:
  /// **'Weak-spot profile'**
  String get pzWeaknessTitle;

  /// No description provided for @pzWeaknessRange.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get pzWeaknessRange;

  /// No description provided for @pzWeaknessFromSessions.
  ///
  /// In en, this message translates to:
  /// **'Compiled from {count} sessions'**
  String pzWeaknessFromSessions(int count);

  /// No description provided for @pzWeaknessTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get pzWeaknessTracked;

  /// No description provided for @pzWeaknessNearlyFixed.
  ///
  /// In en, this message translates to:
  /// **'Nearly fixed'**
  String get pzWeaknessNearlyFixed;

  /// No description provided for @pzWeaknessNewlyFound.
  ///
  /// In en, this message translates to:
  /// **'Newly found'**
  String get pzWeaknessNewlyFound;

  /// No description provided for @pzWeaknessGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get pzWeaknessGrammar;

  /// No description provided for @pzWeaknessPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pzWeaknessPronunciation;

  /// No description provided for @pzWeaknessExpression.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get pzWeaknessExpression;

  /// No description provided for @pzWeaknessSevere.
  ///
  /// In en, this message translates to:
  /// **'SEVERE'**
  String get pzWeaknessSevere;

  /// No description provided for @pzWeaknessNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get pzWeaknessNew;

  /// No description provided for @pzWeaknessImproving.
  ///
  /// In en, this message translates to:
  /// **'IMPROVING'**
  String get pzWeaknessImproving;

  /// No description provided for @pzWeaknessMild.
  ///
  /// In en, this message translates to:
  /// **'MILD'**
  String get pzWeaknessMild;

  /// No description provided for @pzWeaknessBuildSession.
  ///
  /// In en, this message translates to:
  /// **'Build a session from the top 3'**
  String get pzWeaknessBuildSession;

  /// No description provided for @pzInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get pzInterestsTitle;

  /// No description provided for @pzInterestsDiscovered.
  ///
  /// In en, this message translates to:
  /// **'I NOTICED SOMETHING'**
  String get pzInterestsDiscovered;

  /// No description provided for @pzInterestsConfidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% confident'**
  String pzInterestsConfidence(int percent);

  /// No description provided for @pzInterestsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to interests'**
  String get pzInterestsAdd;

  /// No description provided for @pzInterestsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pzInterestsDismiss;

  /// No description provided for @pzInterestsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get pzInterestsActive;

  /// No description provided for @pzInterestsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get pzInterestsEdit;

  /// No description provided for @pzInterestsCooling.
  ///
  /// In en, this message translates to:
  /// **'Cooling down'**
  String get pzInterestsCooling;

  /// No description provided for @pzInterestsKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get pzInterestsKeep;

  /// No description provided for @pzInterestsAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update automatically'**
  String get pzInterestsAutoUpdate;

  /// No description provided for @pzInterestsAutoUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Let me change the suggested topics based on what you actually talk about.'**
  String get pzInterestsAutoUpdateBody;

  /// No description provided for @pzInterestsFooter.
  ///
  /// In en, this message translates to:
  /// **'Every change shows up here before it affects your practice.'**
  String get pzInterestsFooter;

  /// No description provided for @pzProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get pzProgressTitle;

  /// No description provided for @pzProgressRangeFourWeeks.
  ///
  /// In en, this message translates to:
  /// **'4 weeks'**
  String get pzProgressRangeFourWeeks;

  /// No description provided for @pzProgressRangeThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get pzProgressRangeThreeMonths;

  /// No description provided for @pzProgressRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get pzProgressRangeAll;

  /// No description provided for @pzProgressAverage.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get pzProgressAverage;

  /// No description provided for @pzProgressRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get pzProgressRecentSessions;

  /// No description provided for @pzOnboardingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build your speaking profile'**
  String get pzOnboardingIntroTitle;

  /// No description provided for @pzOnboardingIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions so every practice session is picked for you — your level, your interests, your weak spots.'**
  String get pzOnboardingIntroBody;

  /// No description provided for @pzOnboardingIntroStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get pzOnboardingIntroStart;

  /// No description provided for @pzOnboardingIntroDuration.
  ///
  /// In en, this message translates to:
  /// **'About 3 minutes · no right answers'**
  String get pzOnboardingIntroDuration;

  /// No description provided for @pzOnboardingQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Your learning style'**
  String get pzOnboardingQuizTitle;

  /// No description provided for @pzOnboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String pzOnboardingProgress(int current, int total);

  /// No description provided for @pzOnboardingQuizTip.
  ///
  /// In en, this message translates to:
  /// **'There are no right answers — answer honestly so the plan fits you.'**
  String get pzOnboardingQuizTip;

  /// No description provided for @pzOnboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get pzOnboardingBack;

  /// No description provided for @pzOnboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get pzOnboardingContinue;

  /// No description provided for @pzOnboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get pzOnboardingSkip;

  /// No description provided for @pzOnboardingInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests & goals'**
  String get pzOnboardingInterestsTitle;

  /// No description provided for @pzOnboardingInterestsHeading.
  ///
  /// In en, this message translates to:
  /// **'What do you want to talk about?'**
  String get pzOnboardingInterestsHeading;

  /// No description provided for @pzOnboardingInterestsBody.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3 topics. I\'ll use exactly these for your speaking practice — and update them as you start talking about other things.'**
  String get pzOnboardingInterestsBody;

  /// No description provided for @pzOnboardingMainGoal.
  ///
  /// In en, this message translates to:
  /// **'Main goal'**
  String get pzOnboardingMainGoal;

  /// No description provided for @pzOnboardingContinueWithCount.
  ///
  /// In en, this message translates to:
  /// **'Continue · {count} topics picked'**
  String pzOnboardingContinueWithCount(int count);

  /// No description provided for @pzOnboardingPickThree.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3 topics'**
  String get pzOnboardingPickThree;

  /// No description provided for @pzOnboardingProfileHeader.
  ///
  /// In en, this message translates to:
  /// **'YOUR LEARNING PROFILE'**
  String get pzOnboardingProfileHeader;

  /// No description provided for @pzOnboardingCefr.
  ///
  /// In en, this message translates to:
  /// **'Estimated CEFR'**
  String get pzOnboardingCefr;

  /// No description provided for @pzOnboardingFlas.
  ///
  /// In en, this message translates to:
  /// **'Attitude & motivation (FLAS)'**
  String get pzOnboardingFlas;

  /// No description provided for @pzOnboardingRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Suggested 4-week plan'**
  String get pzOnboardingRoadmap;

  /// No description provided for @pzOnboardingStartFirst.
  ///
  /// In en, this message translates to:
  /// **'Start your first session'**
  String get pzOnboardingStartFirst;

  /// No description provided for @pzOnboardingRestart.
  ///
  /// In en, this message translates to:
  /// **'Redo speaking onboarding'**
  String get pzOnboardingRestart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
