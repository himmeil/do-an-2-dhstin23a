class PlaceComment {
  const PlaceComment({
    required this.id,
    required this.accountName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String accountName;
  final String content;
  final DateTime? createdAt;
}
