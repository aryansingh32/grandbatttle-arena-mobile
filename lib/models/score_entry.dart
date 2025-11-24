class ScoreEntry {
  final String playerName;
  final String teamName;
  final int kills;
  final int coinsEarned;
  final int placement;

  ScoreEntry({
    required this.playerName,
    required this.teamName,
    required this.kills,
    required this.coinsEarned,
    required this.placement,
  });

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      playerName: json['playerName'] ?? 'Unknown',
      teamName: json['teamName'] ?? '-',
      kills: json['kills'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
      placement: json['placement'] ?? 0,
    );
  }
}

