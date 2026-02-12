class TeamCreateRequest {
  final String teamName;

  TeamCreateRequest({required this.teamName});

  Map<String, dynamic> toJson() => {'teamname': teamName};
}