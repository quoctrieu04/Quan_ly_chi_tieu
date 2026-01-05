import 'package:chitieu/pages/budget_edit_page.dart';
import 'package:chitieu/utils/safe_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chitieu/api/category/category_provider.dart';
import 'package:chitieu/api/category/category_model.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  /// 'out' = Chi (mặc định), 'in' = Thu
  String _type = 'out';

  Future<void> _refresh() async {
    await context.read<CategoryProvider>().fetchAll(type: _type);
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetEditPage(type: _type), // 👈 truyền loại hiện tại
      ),
    );
    if (created == true) {
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã tạo danh mục')),
        );
      }
    }
  }

  Future<void> _edit(Category c) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetEditPage(category: c, type: _type), // 👈
      ),
    );
    if (changed == true) {
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã cập nhật danh mục')),
        );
      }
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Xoá danh mục "${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<CategoryProvider>().delete(id: c.id);
      await _refresh();
      if (mounted) {
        safeShowSnackBar(
          context,
          const SnackBar(content: Text('Đã xoá danh mục')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      safeShowSnackBar(
        context,
        SnackBar(content: Text('Xoá thất bại: $e')),
      );
    }
  }

  void _changeType(String newType) {
    if (_type == newType) return;
    setState(() => _type = newType);
    // tải lại theo loại mới
    // ignore: discarded_futures
    _refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    String titleForType(String t) => t == 'in' ? 'Danh mục THU' : 'Danh mục CHI';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleForType(_type)),
        actions: [
          // Bộ chọn Chi / Thu
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PopupMenuButton<String>(
              tooltip: 'Chọn loại',
              onSelected: _changeType,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'out', child: Text('Danh mục Chi')),
                PopupMenuItem(value: 'in', child: Text('Danh mục Thu')),
              ],
              child: Row(
                children: [
                  Text(_type == 'in' ? 'Thu' : 'Chi',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 2),
                  const Icon(Icons.swap_vert_rounded),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm danh mục',
            onPressed: _create,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Chưa có danh mục')),
                  ])
                : ListView.separated(
                    itemCount: provider.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = provider.items[i];
                      return ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(c.name),
                        subtitle: Text(_type == 'in' ? 'Thu' : 'Chi'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Sửa',
                              onPressed: () => _edit(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Xoá',
                              onPressed: () => _delete(c),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
