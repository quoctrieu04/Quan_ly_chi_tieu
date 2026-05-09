/// Đánh giá biểu thức toán học cơ bản (cộng, trừ, nhân, chia)
/// Ví dụ: "100+20*2" -> 240
int evaluateMathExpression(String expr) {
  try {
    String s = expr;
    List<String> tokens = [];
    String num = '';
    for (var i = 0; i < s.length; i++) {
      var c = s[i];
      if ('+-*/'.contains(c)) {
        if (num.isNotEmpty) tokens.add(num);
        tokens.add(c);
        num = '';
      } else {
        num += c;
      }
    }
    if (num.isNotEmpty) tokens.add(num);

    if (tokens.isEmpty) return 0;
    double res = double.tryParse(tokens[0]) ?? 0;
    for (var i = 1; i < tokens.length - 1; i += 2) {
      var op = tokens[i];
      var next = double.tryParse(tokens[i + 1]) ?? 0;
      if (op == '+') {
        res += next;
      } else if (op == '-') {
        res -= next;
      } else if (op == '*') {
        res *= next;
      } else if (op == '/') {
        res /= next;
      }
    }
    return res.toInt();
  } catch (_) {
    return int.tryParse(expr) ?? 0;
  }
}
