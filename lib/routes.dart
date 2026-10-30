/// The app's pages and their URL paths. On the web they appear after `#`,
/// for example `/#/alarms`.
enum AppRoute {
  alarms('/alarms'),
  library('/library'),
  insights('/insights'),
  settings('/settings'),
  ringing('/ringing');

  new(this.path);

  /// Path for `context.go` and `context.push`.
  final String path;
}
