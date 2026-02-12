class TeamModel {
  final int teamId;
  final String teamName;

  TeamModel({required this.teamId, required this.teamName});

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(teamId: json['teamid'], teamName: json['teamname']);
  }
}
