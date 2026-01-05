import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chitieu/api/saving/saving_model.dart';
import 'package:chitieu/api/saving/saving_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_provider.dart';
import 'package:chitieu/api/bankaccount/bank_account_model.dart';

class SavingTransactionForm extends StatefulWidget {
  final SavingModel saving;

  const SavingTransactionForm({super.key, required this.saving});

  @override
  State<SavingTransactionForm> createState() => _SavingTransactionFormState();
}

class _SavingTransactionFormState extends State<SavingTransactionForm> {
  bool isDeposit = true;
  double amount = 0;
  String note = "";
  BankAccount? selectedWallet;

  final fmt = NumberFormat.decimalPattern('vi_VN');

  void addDigit(int d) => setState(() => amount = amount * 10 + d);

  void deleteDigit() => setState(() => amount = (amount ~/ 10).toDouble());

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<BankAccountProvider>().items;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giao dịch tiết kiệm"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            /// --- Nạp / Rút ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Nạp vào"),
                  selected: isDeposit,
                  onSelected: (_) => setState(() => isDeposit = true),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("Rút ra"),
                  selected: !isDeposit,
                  onSelected: (_) => setState(() => isDeposit = false),
                )
              ],
            ),

            const SizedBox(height: 16),

            /// --- Số tiền ---
            Text(
              "${fmt.format(amount)}đ",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// --- Chọn ví ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<BankAccount>(
                decoration: InputDecoration(
                  labelText: isDeposit ? "Rút từ ví" : "Nhận về ví",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: wallets
                    .map((w) => DropdownMenuItem(
                          value: w,
                          child: Text("${w.name} (${fmt.format(w.balance)}đ)"),
                        ))
                    .toList(),
                onChanged: (v) => selectedWallet = v,
              ),
            ),

            /// --- Ghi chú ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes),
                  hintText: "Ghi chú...",
                ),
                onChanged: (v) => note = v,
              ),
            ),

            const SizedBox(height: 12),

            /// --- Bàn phím số (Expandable) ---
            Expanded(child: _keypad()),

            /// --- Nút lưu ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: cs.primary,
                  ),
                  onPressed: save,
                  child: Text(
                    isDeposit ? "Nạp vào tiết kiệm" : "Rút tiết kiệm",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== KEYPAD =====
  Widget _keypad() {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      crossAxisCount: 3,
      childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (int i = 1; i <= 9; i++) _key("$i", () => addDigit(i)),
        const SizedBox(),
        _key("0", () => addDigit(0)),
        _key("⌫", deleteDigit),
      ],
    );
  }

  Widget _key(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  /// ===== SAVE =====
  Future<void> save() async {
    if (selectedWallet == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thiếu dữ liệu")),
      );
      return;
    }

    final realAmount = isDeposit ? amount : -amount;

    final ok = await context.read<SavingProvider>().addTransaction(
          savingId: widget.saving.id,
          bankId: selectedWallet!.id,
          amount: realAmount,
          note: note,
        );

    if (ok && mounted) Navigator.pop(context, true);
  }
}
