/// Interface chung cho mọi Provider có thể làm mới dữ liệu.
/// Nhờ đó UI chỉ cần gọi provider.refresh().
abstract class Refreshable {
  Future<void> refresh();
}
