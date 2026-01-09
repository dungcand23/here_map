enum B2BRole {
  owner,
  dispatcher,
  driver;

  static B2BRole fromString(String v) {
    switch (v) {
      case 'owner':
        return B2BRole.owner;
      case 'dispatcher':
        return B2BRole.dispatcher;
      case 'driver':
      default:
        return B2BRole.driver;
    }
  }

  String get value => name;

  bool get canEditRoutes => this == B2BRole.owner || this == B2BRole.dispatcher;
  bool get canManageTeam => this == B2BRole.owner;
}
