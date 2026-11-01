/// Bỏ dấu tiếng Việt và đưa về chữ thường, để tìm kiếm "ca phe" ra "Cà phê".
String foldVietnamese(String input) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final map = <String, String>{
    for (final entry in groups.entries)
      for (final ch in entry.value.split('')) ch: entry.key,
  };
  // Xóa dấu rời (khi chữ được gõ ở dạng tổ hợp) rồi thay từng ký tự có dấu.
  final lower = input.toLowerCase().replaceAll(RegExp('[\u0300-\u036f]'), '');
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}
