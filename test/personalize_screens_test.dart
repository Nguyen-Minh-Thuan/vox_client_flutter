import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_client_flutter/app/theme.dart';
import 'package:vox_client_flutter/features/personalize/data/personalize_demo_data.dart';
import 'package:vox_client_flutter/features/personalize/presentation/interests_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/onboarding/onboarding_flow.dart';
import 'package:vox_client_flutter/features/personalize/presentation/practice_home_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/practice_session_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/practice_topics_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/progress_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/session_summary_screen.dart';
import 'package:vox_client_flutter/features/personalize/presentation/weakness_profile_screen.dart';
import 'package:vox_client_flutter/l10n/app_localizations.dart';

/// Smoke coverage for the personalized-practice screens.
///
/// These screens are laid out against a 390×844 mockup but must also survive a
/// narrow phone, so every case is pumped at 360×640 — an overflow there fails
/// the test via the "RenderFlex overflowed" exception.
void main() {
  Widget host(Widget child, {Locale locale = const Locale('vi')}) {
    return MaterialApp(
      locale: locale,
      theme: buildTheme(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
  }

  setUp(() {
    // Narrow phone — the tightest layout the screens need to survive.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(720, 1280);
    view.devicePixelRatio = 2.0;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize();
  });

  testWidgets('practice home renders the dashboard', (tester) async {
    await tester.pumpWidget(host(const PracticeHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text(PersonalizeDemoData.dashboard.learnerName), findsOneWidget);
    expect(find.text(PersonalizeDemoData.daLatTopic.title), findsOneWidget);
    // The three stat boxes.
    expect(find.text('24'), findsOneWidget);
    expect(find.text('7.8'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
  });

  testWidgets('topics screen promotes the best match and filters', (tester) async {
    await tester.pumpWidget(host(const PracticeTopicsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ƯU TIÊN #1'), findsOneWidget);
    expect(find.text(PersonalizeDemoData.topFootballTopic.title), findsOneWidget);

    // Switching to "Đã lưu" swaps the list for the saved bucket. The pill row
    // scrolls horizontally, so bring the pill on screen before tapping it.
    await tester.scrollUntilVisible(find.text('Đã lưu'), 80, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text(PersonalizeDemoData.topFootballTopic.title), findsNothing);
    expect(find.text('Chuyến đi khiến bạn thay đổi cách nghĩ'), findsOneWidget);
  });

  testWidgets('session opens on the AI prompt with the mic idle', (tester) async {
    await tester.pumpWidget(
      host(const PracticeSessionScreen(topic: PersonalizeDemoData.daLatTopic)),
    );
    // The session runs a 1 s clock, so it never "settles" — pump explicitly
    // past the repository latency instead.
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text('So — where did you go last weekend, and who was with you?'),
      findsOneWidget,
    );
    expect(find.text('Bấm mic để trả lời'), findsOneWidget);
    // Nothing is graded until the learner speaks.
    expect(find.textContaining('SỬA NGAY'), findsNothing);
  });

  testWidgets('summary shows score, rubric and repeated errors', (tester) async {
    await tester.pumpWidget(
      host(const SessionSummaryScreen(sessionId: 'session-da-lat')),
    );
    await tester.pumpAndSettle();

    expect(find.text('8.1'), findsOneWidget);
    expect(find.textContaining('+0.4'), findsOneWidget);
    // Rubric labels are rich text (label + weight), so match on a substring.
    expect(
      find.textContaining('Ngữ pháp', findRichText: true),
      findsOneWidget,
    );
    // The repeated-errors card sits below the fold on a narrow screen.
    await tester.scrollUntilVisible(find.text('×4'), 120);
    expect(find.text('×4'), findsOneWidget);
  });

  testWidgets('weakness profile groups by category', (tester) async {
    await tester.pumpWidget(host(const WeaknessProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Thì quá khứ đơn'), findsOneWidget);
    expect(find.text('NẶNG'), findsOneWidget);
    expect(find.text('ĐANG TỐT LÊN'), findsOneWidget);
  });

  testWidgets('accepting a discovered interest moves it to active',
      (tester) async {
    await tester.pumpWidget(host(const InterestsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('MÌNH PHÁT HIỆN THÊM'), findsOneWidget);

    await tester.tap(find.text('Thêm vào sở thích'));
    await tester.pumpAndSettle();

    expect(find.text('MÌNH PHÁT HIỆN THÊM'), findsNothing);
    expect(find.text('🍜 Ẩm thực & nấu ăn'), findsOneWidget);
  });

  testWidgets('progress screen switches range', (tester) async {
    await tester.pumpWidget(host(const ProgressScreen()));
    await tester.pumpAndSettle();

    // 8.1 appears twice: the average headline and today's session in the list.
    expect(find.text('8.1'), findsNWidgets(2));

    await tester.tap(find.text('3 tháng'));
    await tester.pumpAndSettle();
    expect(find.text('7.6'), findsOneWidget);
  });

  testWidgets('onboarding gates Continue until an option is picked',
      (tester) async {
    await tester.pumpWidget(host(const OnboardingFlow()));
    await tester.pumpAndSettle();

    expect(find.text('1/12'), findsOneWidget);
    expect(
      find.text('Khi phải nói tiếng Anh trước cả lớp, mình thường thấy…'),
      findsOneWidget,
    );

    // Continue is inert until an answer exists.
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('1/12'), findsOneWidget);

    await tester.tap(find.text('Bình thường, tuỳ chủ đề'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('2/12'), findsOneWidget);
  });

  testWidgets('screens are localized — English swaps every label',
      (tester) async {
    await tester.pumpWidget(
      host(const PracticeHomeScreen(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text("TODAY'S SESSION"), findsOneWidget);
    expect(find.text('PERSONALIZED'), findsOneWidget);
    expect(find.text('PHIÊN HÔM NAY'), findsNothing);
  });
}
