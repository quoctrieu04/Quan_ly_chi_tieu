// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Chi Tiêu';

  @override
  String get tabBudgets => 'Ngân sách';

  @override
  String get tabAccounts => 'Tài khoản';

  @override
  String get tabAnalytics => 'Phân tích';

  @override
  String get tabSettings => 'Cài đặt';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get userNamePlaceholder => 'Khách';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get brightness => 'Sáng / Tối';

  @override
  String get color => 'Màu chủ đạo';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get fontSmall => 'Nhỏ';

  @override
  String get fontNormal => 'Bình thường';

  @override
  String get fontLarge => 'Lớn';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get policy => 'Điều lệ & Bảo mật';

  @override
  String get view => 'Xem';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutSuccess => 'Đã đăng xuất';

  @override
  String get budgetsTitle => 'Ngân sách tháng';

  @override
  String get budgetsDescription => 'Quản lý hạn mức và các hạng mục chi tiêu.';

  @override
  String get accountsTitle => 'Tài khoản';

  @override
  String get accountsDescription => 'Liên kết ngân hàng, ví điện tử và số dư hiện tại.';

  @override
  String get analyticsTitle => 'Phân tích';

  @override
  String get analyticsDescription => 'Xem phân tích chi tiêu và ngân sách';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get loginSubmit => 'Đăng nhập';

  @override
  String get totalAssets => 'Tổng tiền';

  @override
  String get payment => 'Thanh toán';

  @override
  String get tracking => 'Theo dõi';

  @override
  String get createWallet => 'Tạo khoản thu';

  @override
  String get transactionHistory => 'Lịch sử giao dịch';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get startAddingMoneyTitle => 'Hãy bắt đầu thêm khoản thu tháng này của bạn!';

  @override
  String get startAddingMoneyHint => 'Bạn nhập càng chính xác thì ứng dụng sẽ giúp bạn tính toán dữ liệu càng chuẩn!';

  @override
  String get readyMoneyShort => 'Tiền sẵn sàng để...';

  @override
  String get openingBalance => 'Số dư khởi điểm';

  @override
  String get monthly => 'Tiền tháng';

  @override
  String get monthlyClosed => 'Tiền tháng (đã đóng)';

  @override
  String get travelDeleted => 'Du lịch (đã xoá)';

  @override
  String get noDescription => 'Không có mô tả';

  @override
  String get cash => 'Tiền mặt';

  @override
  String get accountsStartTitle => 'Hãy bắt đầu thêm nguồn thu của bạn!';

  @override
  String get accountsStartHint => 'Bạn nhập càng chính xác thì ứng dụng sẽ giúp bạn tính toán dữ liệu thông tin càng chuẩn!';

  @override
  String get noTransactionsHint => 'Chưa có giao dịch nào. Hãy bắt đầu ghi chép chi tiêu đầu tiên của bạn!';

  @override
  String get monthBadge => 'Tiền tháng';

  @override
  String get noteAddDescription => 'Thêm mô tả...';

  @override
  String get moneyOut => 'Tiền ra';

  @override
  String get moneyIn => 'Tiền vào';

  @override
  String get category => 'Danh mục';

  @override
  String get walletName => 'Khoản thu';

  @override
  String get initialAmount => 'Số tiền ban đầu';

  @override
  String get requiredField => 'Không được để trống';

  @override
  String get invalidNumber => 'Số không hợp lệ';

  @override
  String get save => 'Lưu';

  @override
  String get walletCreated => 'Đã thêm nguồn thu';

  @override
  String get needLogin => 'Cần đăng nhập';

  @override
  String get needLoginContent => 'Bạn cần đăng nhập.';

  @override
  String get cancel => 'Huỷ';

  @override
  String get noData => 'No data available';

  @override
  String get somethingWrong => 'Đã có lỗi xảy ra, vui lòng thử lại';

  @override
  String get createBudgetCta => 'Create budget';

  @override
  String get moneyAssigned => 'Đã phân bổ';

  @override
  String get moneyUnassigned => 'Chưa phân bổ';

  @override
  String get assignMoneyCta => 'Phân bổ tiền';

  @override
  String get trialReminderTitle => 'Chọn gói trial của bạn';

  @override
  String trialReminderSubtitle(String date) {
    return 'Chọn gói trial của bạn trước ngày $date để không gián đoạn sử dụng app!';
  }

  @override
  String get viewPackagesCta => 'Xem các gói';

  @override
  String get createCategoryTitle => 'Danh mục';

  @override
  String get createCategoryDescription => 'Nhóm các khoản chi theo danh mục để dễ dàng theo dõi tiền đi đâu.';

  @override
  String get createFromSuggested => 'Tạo từ danh mục gợi ý';

  @override
  String get createMyOwn => 'Tạo danh mục của tôi';

  @override
  String get budgetSettingsTitle => 'Cài đặt Ngân sách';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get numberFormat => 'Định dạng số tiền';

  @override
  String get currencySymbolPosition => 'Vị trí Ký hiệu Tiền tệ';

  @override
  String get symbolBefore => 'Trước số tiền';

  @override
  String get symbolAfter => 'Sau số tiền';

  @override
  String monthYearTitle(Object monthName, Object year) {
    return '$monthName $year';
  }

  @override
  String monthGridLabel(Object month) {
    return '$month';
  }

  @override
  String get remaining => 'Còn lại';

  @override
  String get editAllocationCta => 'Chỉnh sửa phân bổ';

  @override
  String get goalTitle => 'Đặt mục tiêu';

  @override
  String get goalSubtitle => 'Hãy đạt được ước mơ tài chính bằng cách đặt mục tiêu tiết kiệm.';

  @override
  String get createGoalCta => 'Tạo mục tiêu';

  @override
  String get txHistoryTitle => 'Lịch sử giao dịch';

  @override
  String txSpentTotal(Object amount) {
    return 'Đã chi tổng cộng: $amount';
  }

  @override
  String get monthlyBudgetTitle => 'Ngân sách tháng';

  @override
  String trialBannerText(Object deadline) {
    return 'Your free trial ends on $deadline';
  }

  @override
  String get viewPlansCta => 'Xem gói';

  @override
  String get groupRequiredCosts => 'Danh mục chi tiêu';

  @override
  String get categoryRent => 'Tiền nhà';

  @override
  String get spent => 'Đã tiêu';

  @override
  String get ofTotal => 'trên';

  @override
  String get addCategoryTooltip => 'Thêm danh mục';

  @override
  String get addCategoryFab => '';

  @override
  String get createCategoryTitleForm => 'Tạo danh mục mới';

  @override
  String get selectIconLabel => 'Chọn biểu tượng';

  @override
  String get categoryNameLabel => 'Tên danh mục';

  @override
  String get categoryNameHint => 'Nhập tên (ví dụ: Tiền nhà, Ăn uống...)';

  @override
  String get categoryNameRequired => 'Tên danh mục không được để trống';

  @override
  String get saveCta => 'Lưu';

  @override
  String get cancelCta => 'Huỷ';

  @override
  String get noCategoryHint => 'Chưa có danh mục. Nhấn nút + để tạo danh mục đầu tiên.';

  @override
  String get editBudgetTitle => 'Chỉnh sửa ngân sách';

  @override
  String get createCategoryGroupCta => 'TẠO DANH MỤC';

  @override
  String get reorderDeleteCategoriesCta => 'SẮP XẾP/XÓA DANH MỤC';

  @override
  String get renameCta => 'SỬA TÊN';

  @override
  String get loginRequiredMessage => 'Vui lòng đăng nhập để tiếp tục';

  @override
  String get editCategoryTitle => 'Sửa danh mục';

  @override
  String get updateCta => 'Cập nhật';

  @override
  String get needLoginBudgets => 'Bạn cần đăng nhập';

  @override
  String get allocateTitle => 'Phân chia tiền vào ngân sách';

  @override
  String get availableNow => 'Đang có';

  @override
  String get allocated => 'Đã phân bổ';

  @override
  String get saveAllAllocations => 'LƯU TẤT CẢ PHÂN BỔ';

  @override
  String get remainingToAllocate => 'Còn lại chưa phân bổ';

  @override
  String get inputAllocateTitle => 'Nhập số tiền muốn phân bổ';

  @override
  String get moneyInputHint => 'Ví dụ: 500000';

  @override
  String get ok => 'OK';

  @override
  String get genericFailedMessage => 'Thao tác thất bại';

  @override
  String get available => 'Đang có';

  @override
  String get spentLabel => 'Đã tiêu:';

  @override
  String get enterAmountTitle => 'Nhập số tiền muốn phân bổ';

  @override
  String get hintAmountExample => 'Ví dụ: 30.000';

  @override
  String get remainingUnallocated => 'Còn lại chưa phân bổ:';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get categoryDetails => 'Chi tiết danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get assignedMoney => 'Số tiền phân bổ';

  @override
  String get saved => 'Đã lưu';

  @override
  String get delete => 'Xoá';

  @override
  String get areYouSureDelete => 'Bạn có chắc muốn xoá danh mục này?';

  @override
  String get fieldRequired => 'Vui lòng nhập thông tin';

  @override
  String get numberInvalid => 'Số không hợp lệ';

  @override
  String get mustBePositive => 'Phải là số không âm';

  @override
  String get tooLong => 'Quá dài';

  @override
  String get analyticsBudgetSplit => 'Phân bổ theo danh mục';

  @override
  String get topCategories => 'Danh mục nổi bật';

  @override
  String get summary => 'Tổng kết';

  @override
  String get noDataThisMonth => 'Không có dữ liệu cho tháng này';

  @override
  String get selectMonth => 'Chọn tháng';

  @override
  String get totalAssigned => 'Tổng phân bổ';

  @override
  String get confirmTitle => 'Xác nhận';

  @override
  String confirmDeleteMessage(Object name) {
    return 'Bạn có chắc muốn xoá danh mục $name?';
  }

  @override
  String get deleteCta => 'Xoá';

  @override
  String get editCategories => 'Chỉnh sửa danh mục';

  @override
  String get plannedUpperCase => 'ĐÃ CÓ KẾ HOẠCH';

  @override
  String get remainingUpperCase => 'CÒN LẠI';

  @override
  String get safeToSave => 'An toàn dự trữ';

  @override
  String get deficit => 'Thâm hụt!';

  @override
  String get fundingSource => 'Nguồn tiền';

  @override
  String get savings => 'Tiết kiệm';

  @override
  String get investment => 'Đầu tư';

  @override
  String get overview => 'Tổng quan';

  @override
  String get income => 'Thu vào';

  @override
  String get expense => 'Chi ra';

  @override
  String get incomeExpenseFluctuation => 'Biến động thu/chi';

  @override
  String get incomeLabel => 'Thu nhập';

  @override
  String get expenseLabel => 'Chi tiêu';

  @override
  String get interfaceSettings => 'Giao diện';

  @override
  String get moneyFormat => 'Định dạng tiền';

  @override
  String get accountSettings => 'Tài khoản';

  @override
  String get loggedIn => 'Đã đăng nhập';

  @override
  String get predictionAndWarning => 'Dự báo & Cảnh báo';

  @override
  String get notEnoughDataTitle => 'Chưa đủ dữ liệu để dự báo';

  @override
  String get notEnoughDataDesc => 'Hiện tại app chưa có đủ dữ liệu để dự đoán chi tiêu. Hãy tiếp tục ghi nhận giao dịch như bình thường; khi dữ liệu đạt đủ điều kiện theo mô hình AI, dự báo và cảnh báo sẽ tự động hoạt động.';

  @override
  String get totalSpentPieChart => 'Tổng chi';

  @override
  String get incomeCollected => 'Đã thu';

  @override
  String get planLabel => 'Kế hoạch';

  @override
  String get overLabel => 'Vượt';

  @override
  String get notSetLabel => 'Chưa đặt';

  @override
  String get guideReview => 'Xem lại hướng dẫn sử dụng';

  @override
  String get notAssignedBudget => 'Chưa cấp ngân sách';

  @override
  String get approachingPlan => 'Sắp chạm kế hoạch';

  @override
  String get overPlan => 'Đã vượt Kế hoạch';

  @override
  String get overspentWarningTitle => '💸 Ui chao! Cảnh báo lạm chi!';

  @override
  String overspentWarningMessage(Object category) {
    return 'Bạn lại lỡ tay vung quá trán cho khoản \"$category\" mất rồi! Đừng để rỗng túi nhé, từ giờ tới cuối tháng hãy \"thắt lưng buộc bụng\" nha.';
  }

  @override
  String get gotIt => 'Biết rồi khổ lắm nói mãi!';
}
