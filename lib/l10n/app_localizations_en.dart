// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get panel => 'Panel';

  @override
  String get traffic => 'Traffic';

  @override
  String get editNode => 'Edit Node';

  @override
  String get icon => 'Icon';

  @override
  String get nodeName => 'Node Name';

  @override
  String get nameHint => 'The name of the node.';

  @override
  String get nameError => 'Node name is required';

  @override
  String get ip => 'IP Address';

  @override
  String get ipHint => 'IP address of the node';

  @override
  String get ipError => 'IP address is required';

  @override
  String get community => 'Community';

  @override
  String get communityHint => 'SNMP Community';

  @override
  String get communityError => 'Invalid coummunity';

  @override
  String get laptop => 'Laptop';

  @override
  String get desktop => 'Desktop';

  @override
  String get lan => 'LAN';

  @override
  String get cloud => 'Cloud';

  @override
  String get server => 'Server';

  @override
  String get pingCount => 'Count';

  @override
  String get pingCountHint => 'Ping Count';

  @override
  String get pingTimeout => 'Timeout';

  @override
  String get pingTimeoutHint => 'Ping Timeout';

  @override
  String get pingTTL => 'TTL';

  @override
  String get pingTTLHint => 'Ping TTL';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get max => 'Max';

  @override
  String get min => 'Min';

  @override
  String get mean => 'Mean';

  @override
  String get median => 'Median';

  @override
  String get sd => 'Standard Deviation';

  @override
  String get mibName => 'Object name';

  @override
  String get mibValue => 'Value';

  @override
  String get interval => 'Interval';

  @override
  String get showAllPort => 'Show all port';

  @override
  String get target => 'Target';

  @override
  String get settings => 'Settings';

  @override
  String get count => 'Count';

  @override
  String get timeout => 'Timeout';

  @override
  String get retry => 'Retry';

  @override
  String get sec => 'Sec';

  @override
  String get mibBrowser => 'MIB Browser';

  @override
  String get hostResource => 'Host Resource';

  @override
  String get processes => 'Processes';

  @override
  String get port => 'TCP/UDP Port List';

  @override
  String get key => 'Name';

  @override
  String get value => 'Value';

  @override
  String get path => 'Path';

  @override
  String get type => 'Type';

  @override
  String get status => 'Status';

  @override
  String get showProcessMode => 'Process Sort Mode';

  @override
  String get processName => 'Process Name';

  @override
  String get cert => 'Server Certificate';

  @override
  String get verify => 'Verify';

  @override
  String get subject => 'Subject';

  @override
  String get issuer => 'Issuer';

  @override
  String get startValidity => 'Start Validity';

  @override
  String get endValidity => 'End Validity';

  @override
  String get version => 'Version';

  @override
  String get certDur => 'Days of Validity';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get signatureAlgorithm => 'Signature Algorithm';

  @override
  String get sha1Thumbprint => 'SHA1 Thumbprint';

  @override
  String get sha256Thumbprint => 'SHA256 Thumbprint';

  @override
  String get algorithmReadableName => 'Algorithm';

  @override
  String get keyLength => 'Key Length';

  @override
  String get keySha1Thumbprint => 'Key SHA1 Thumbprint';

  @override
  String get keySha256Thumbprint => 'Key SHA256 Thumbprint';

  @override
  String get subjectAlternativNames => 'Subject Alternativ Names';

  @override
  String get cRLDistributionPoints => 'CRL Distribution Points';

  @override
  String get ipOrHostPort => 'IP or Host Name :Port';

  @override
  String get getIPFromName => 'Get IP';

  @override
  String get serverTest => 'Server Test';

  @override
  String get requiredError => 'This field is required';

  @override
  String get syslogMsg => 'Syslog Message';

  @override
  String get facility => 'Facility';

  @override
  String get severity => 'Severity';

  @override
  String get timeStamp => 'Time';

  @override
  String get length => 'Length';

  @override
  String get host => 'Host Name';

  @override
  String get trapOID => 'SNMP Trap OID';

  @override
  String get dhcpPort => 'Monitor Port';

  @override
  String get dhcpAddress => 'From Address';

  @override
  String get dhcpType => 'DHCP Type';

  @override
  String get user => 'User';

  @override
  String get password => 'Password';

  @override
  String get mailFrom => 'From';

  @override
  String get mailTo => 'To';

  @override
  String get time => 'Time';

  @override
  String get mailSubject => 'Subject';

  @override
  String get mailBody => 'Message';

  @override
  String get search => 'Search';

  @override
  String get ipOrHost => 'IP or Host Name';

  @override
  String get rrType => 'DNS Record Type';

  @override
  String get macAddress => 'MAC Address';

  @override
  String get vendorCode => 'Vendor Code';

  @override
  String get vendorName => 'Vendor Name';

  @override
  String get tx => 'Tx';

  @override
  String get rx => 'Rx';

  @override
  String get error => 'Error';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get save => 'Save';

  @override
  String get checkPing => 'Check PING';

  @override
  String get checkCertConfig => 'Check Server Certificate';

  @override
  String get runPing => 'Run PING Checks';

  @override
  String get runCert => 'Run Cert Checks';

  @override
  String get checking => 'Checking...';

  @override
  String get checkCompletedCount => 'Completed Nodes';

  @override
  String get checkProblemCount => 'Problem Nodes';

  @override
  String get checkingNode => 'Checking';

  @override
  String get checkFinished => 'Check Finished';
}
