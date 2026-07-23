// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get defaultUserName => 'Người dùng';

  @override
  String get statusActive => 'Hoạt động';

  @override
  String get roleSystemAdmin => 'Quản trị hệ thống';

  @override
  String get roleSchoolAdmin => 'Quản trị trường';

  @override
  String get roleTeacher => 'Giáo viên';

  @override
  String get roleStudent => 'Học sinh';

  @override
  String get statPracticesDone => 'Bài đã luyện';

  @override
  String get statAverageScore => 'Điểm trung bình';

  @override
  String get statDayStreak => 'Chuỗi ngày';

  @override
  String get sectionAccount => 'Tài khoản';

  @override
  String get sectionSettings => 'Cài đặt';

  @override
  String get menuMyResults => 'Kết quả của tôi';

  @override
  String get menuRecordings => 'Bản ghi âm';

  @override
  String get menuAppeals => 'Khiếu nại & Chấm lại';

  @override
  String get menuLanguage => 'Ngôn ngữ';

  @override
  String get menuNotifications => 'Thông báo';

  @override
  String get menuLogOut => 'Đăng xuất';

  @override
  String get profileLoadError => 'Không thể tải thông tin hồ sơ.';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navSchedule => 'Lịch';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get greetingLateNight => 'Luyện tập khuya nhỉ?';

  @override
  String get greetingMorning => 'Buổi sáng tốt lành';

  @override
  String get greetingAfternoon => 'Chào buổi chiều';

  @override
  String get greetingEvening => 'Chào buổi tối';

  @override
  String get homeContinueLearning => 'Tiếp tục với';

  @override
  String get homeExamsToComplete => 'Bài cần hoàn thành';

  @override
  String get homeNoExamsLeft => 'Không còn bài nào cần hoàn thành';

  @override
  String get homeNoDateSet => 'Chưa có ngày';

  @override
  String get homeNotCompleted => 'Chưa hoàn thành';

  @override
  String get homeSearchLessons => 'Tìm bài học…';

  @override
  String get homeResume => 'Tiếp tục →';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsMarkAllRead => 'Đánh dấu đã đọc tất cả';

  @override
  String get notificationsGroupNew => 'Mới';

  @override
  String get notificationsGroupEarlier => 'Trước đó';

  @override
  String get scheduleTitle => 'Lịch của bạn';

  @override
  String scheduleLoadError(String error) {
    return 'Không thể tải lịch của bạn.\n$error';
  }

  @override
  String get scheduleRetry => 'Thử lại';

  @override
  String scheduleToday(String date) {
    return 'Hôm nay · $date';
  }

  @override
  String get scheduleNoSessionsToday => 'Không có buổi nào hôm nay.';

  @override
  String scheduleTomorrow(String date) {
    return 'Ngày mai · $date';
  }

  @override
  String get scheduleNoSessionsTomorrow => 'Không có buổi nào ngày mai.';

  @override
  String get scheduleKindCentralized => 'Kiểm tra tập trung';

  @override
  String get scheduleKindClassTest => 'Kiểm tra trên lớp';

  @override
  String get scheduleTimeUnset => '--:--';

  @override
  String get scheduleJumpToday => 'Hôm nay';

  @override
  String get scheduleLegendHasSession => 'Có buổi kiểm tra';

  @override
  String scheduleRoomLabel(String room) {
    return 'Phòng $room';
  }

  @override
  String get scheduleStatusOpen => 'Đang diễn ra';

  @override
  String get scheduleStatusUpcoming => 'Sắp tới';

  @override
  String get scheduleStatusClosed => 'Đã kết thúc';

  @override
  String get teacherExamClassTestsTab => 'Kiểm tra trên lớp';

  @override
  String get teacherExamCentralizedTab => 'Tập trung';

  @override
  String get teacherExamKindClassTest => 'Kiểm tra trên lớp';

  @override
  String get teacherExamCentralizedSection => 'Kiểm tra tập trung';

  @override
  String get teacherExamNoClassTests => 'Chưa có bài kiểm tra nào.';

  @override
  String get teacherExamNoCentralizedExams =>
      'Bạn chưa được phân công kiểm tra tập trung nào.';

  @override
  String get teacherExamStatusDraft => 'Bản nháp';

  @override
  String get teacherExamStatusScheduled => 'Đã lên lịch';

  @override
  String get teacherExamStatusInProgress => 'Đang diễn ra';

  @override
  String get teacherExamStatusClosed => 'Đã đóng';

  @override
  String get teacherExamStatusResultsPublished => 'Đã công bố kết quả';

  @override
  String get teacherExamStatusCancelled => 'Đã hủy';

  @override
  String get teacherExamActionSchedule => 'Lên lịch';

  @override
  String get teacherExamActionCancel => 'Hủy';

  @override
  String get teacherExamActionStart => 'Bắt đầu';

  @override
  String get teacherExamActionClose => 'Đóng';

  @override
  String get teacherExamActionPublishResults => 'Công bố kết quả';

  @override
  String get classTestUpdateStatusError => 'Không thể cập nhật trạng thái.';

  @override
  String get classTestDeleteTitle => 'Xóa bài kiểm tra?';

  @override
  String classTestDeleteBody(String name) {
    return 'Thao tác này sẽ xóa vĩnh viễn \"$name\".';
  }

  @override
  String get classTestCancel => 'Hủy';

  @override
  String get classTestDelete => 'Xóa';

  @override
  String get classTestDeleteError => 'Không thể xóa bài kiểm tra.';

  @override
  String get classTestOpens => 'Mở lúc';

  @override
  String get classTestCloses => 'Đóng lúc';

  @override
  String get classTestNotSet => 'Chưa đặt';

  @override
  String get classTestActions => 'Hành động';

  @override
  String get classTestNameRequired => 'Tên là bắt buộc.';

  @override
  String get classTestSelectClass => 'Chọn một lớp.';

  @override
  String get classTestSelectQuestion => 'Chọn ít nhất một câu hỏi.';

  @override
  String get classTestSaveError => 'Không thể lưu bài kiểm tra.';

  @override
  String get classTestEditTitle => 'Chỉnh sửa bài kiểm tra';

  @override
  String get classTestNewTitle => 'Bài kiểm tra mới';

  @override
  String get classTestNameLabel => 'Tên';

  @override
  String get classTestDescriptionLabel => 'Mô tả';

  @override
  String get classTestClassLabel => 'Lớp';

  @override
  String get classTestOpensAt => 'Mở lúc';

  @override
  String get classTestClosesAt => 'Đóng lúc';

  @override
  String get classTestQuestions => 'Câu hỏi';

  @override
  String classTestQuestionsSelected(int count) {
    return 'Đã chọn $count';
  }

  @override
  String get classTestSaveButton => 'Lưu';

  @override
  String get classTestCreateButton => 'Tạo bài kiểm tra';

  @override
  String get centralizedExamBlueprint => 'Đề thi mẫu';

  @override
  String get centralizedExamMembers => 'Thành viên';

  @override
  String get centralizedExamNoMembers => 'Chưa có thành viên nào.';

  @override
  String get questionPickerLoadError => 'Không thể tải câu hỏi.';

  @override
  String get questionPickerTitle => 'Chọn câu hỏi';

  @override
  String questionPickerDone(int count) {
    return 'Xong ($count)';
  }

  @override
  String get questionPickerSearchHint => 'Tìm kiếm câu hỏi';
}
