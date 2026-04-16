import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('en')
  ];

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @panel.
  ///
  /// In en, this message translates to:
  /// **'Panel'**
  String get panel;

  /// No description provided for @traffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// No description provided for @editNode.
  ///
  /// In en, this message translates to:
  /// **'Edit Node'**
  String get editNode;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @nodeName.
  ///
  /// In en, this message translates to:
  /// **'Node Name'**
  String get nodeName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'The name of the node.'**
  String get nameHint;

  /// No description provided for @nameError.
  ///
  /// In en, this message translates to:
  /// **'Node name is required'**
  String get nameError;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ip;

  /// No description provided for @ipHint.
  ///
  /// In en, this message translates to:
  /// **'IP address of the node'**
  String get ipHint;

  /// No description provided for @ipError.
  ///
  /// In en, this message translates to:
  /// **'IP address is required'**
  String get ipError;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityHint.
  ///
  /// In en, this message translates to:
  /// **'SNMP Community'**
  String get communityHint;

  /// No description provided for @communityError.
  ///
  /// In en, this message translates to:
  /// **'Invalid coummunity'**
  String get communityError;

  /// No description provided for @laptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get laptop;

  /// No description provided for @desktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get desktop;

  /// No description provided for @lan.
  ///
  /// In en, this message translates to:
  /// **'LAN'**
  String get lan;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloud;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @pingCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get pingCount;

  /// No description provided for @pingCountHint.
  ///
  /// In en, this message translates to:
  /// **'Ping Count'**
  String get pingCountHint;

  /// No description provided for @pingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get pingTimeout;

  /// No description provided for @pingTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'Ping Timeout'**
  String get pingTimeoutHint;

  /// No description provided for @pingTTL.
  ///
  /// In en, this message translates to:
  /// **'TTL'**
  String get pingTTL;

  /// No description provided for @pingTTLHint.
  ///
  /// In en, this message translates to:
  /// **'Ping TTL'**
  String get pingTTLHint;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @mean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get mean;

  /// No description provided for @median.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get median;

  /// No description provided for @sd.
  ///
  /// In en, this message translates to:
  /// **'Standard Deviation'**
  String get sd;

  /// No description provided for @mibName.
  ///
  /// In en, this message translates to:
  /// **'Object name'**
  String get mibName;

  /// No description provided for @mibValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get mibValue;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @showAllPort.
  ///
  /// In en, this message translates to:
  /// **'Show all port'**
  String get showAllPort;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get timeout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sec.
  ///
  /// In en, this message translates to:
  /// **'Sec'**
  String get sec;

  /// No description provided for @mibBrowser.
  ///
  /// In en, this message translates to:
  /// **'MIB Browser'**
  String get mibBrowser;

  /// No description provided for @hostResource.
  ///
  /// In en, this message translates to:
  /// **'Host Resource'**
  String get hostResource;

  /// No description provided for @processes.
  ///
  /// In en, this message translates to:
  /// **'Processes'**
  String get processes;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'TCP/UDP Port List'**
  String get port;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get key;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @showProcessMode.
  ///
  /// In en, this message translates to:
  /// **'Process Sort Mode'**
  String get showProcessMode;

  /// No description provided for @processName.
  ///
  /// In en, this message translates to:
  /// **'Process Name'**
  String get processName;

  /// No description provided for @cert.
  ///
  /// In en, this message translates to:
  /// **'Server Certificate'**
  String get cert;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @issuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// No description provided for @startValidity.
  ///
  /// In en, this message translates to:
  /// **'Start Validity'**
  String get startValidity;

  /// No description provided for @endValidity.
  ///
  /// In en, this message translates to:
  /// **'End Validity'**
  String get endValidity;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @certDur.
  ///
  /// In en, this message translates to:
  /// **'Days of Validity'**
  String get certDur;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @signatureAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Signature Algorithm'**
  String get signatureAlgorithm;

  /// No description provided for @sha1Thumbprint.
  ///
  /// In en, this message translates to:
  /// **'SHA1 Thumbprint'**
  String get sha1Thumbprint;

  /// No description provided for @sha256Thumbprint.
  ///
  /// In en, this message translates to:
  /// **'SHA256 Thumbprint'**
  String get sha256Thumbprint;

  /// No description provided for @algorithmReadableName.
  ///
  /// In en, this message translates to:
  /// **'Algorithm'**
  String get algorithmReadableName;

  /// No description provided for @keyLength.
  ///
  /// In en, this message translates to:
  /// **'Key Length'**
  String get keyLength;

  /// No description provided for @keySha1Thumbprint.
  ///
  /// In en, this message translates to:
  /// **'Key SHA1 Thumbprint'**
  String get keySha1Thumbprint;

  /// No description provided for @keySha256Thumbprint.
  ///
  /// In en, this message translates to:
  /// **'Key SHA256 Thumbprint'**
  String get keySha256Thumbprint;

  /// No description provided for @subjectAlternativNames.
  ///
  /// In en, this message translates to:
  /// **'Subject Alternativ Names'**
  String get subjectAlternativNames;

  /// No description provided for @cRLDistributionPoints.
  ///
  /// In en, this message translates to:
  /// **'CRL Distribution Points'**
  String get cRLDistributionPoints;

  /// No description provided for @ipOrHostPort.
  ///
  /// In en, this message translates to:
  /// **'IP or Host Name :Port'**
  String get ipOrHostPort;

  /// No description provided for @getIPFromName.
  ///
  /// In en, this message translates to:
  /// **'Get IP'**
  String get getIPFromName;

  /// No description provided for @serverTest.
  ///
  /// In en, this message translates to:
  /// **'Server Test'**
  String get serverTest;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredError;

  /// No description provided for @syslogMsg.
  ///
  /// In en, this message translates to:
  /// **'Syslog Message'**
  String get syslogMsg;

  /// No description provided for @facility.
  ///
  /// In en, this message translates to:
  /// **'Facility'**
  String get facility;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @timeStamp.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeStamp;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host Name'**
  String get host;

  /// No description provided for @trapOID.
  ///
  /// In en, this message translates to:
  /// **'SNMP Trap OID'**
  String get trapOID;

  /// No description provided for @dhcpPort.
  ///
  /// In en, this message translates to:
  /// **'Monitor Port'**
  String get dhcpPort;

  /// No description provided for @dhcpAddress.
  ///
  /// In en, this message translates to:
  /// **'From Address'**
  String get dhcpAddress;

  /// No description provided for @dhcpType.
  ///
  /// In en, this message translates to:
  /// **'DHCP Type'**
  String get dhcpType;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @mailFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get mailFrom;

  /// No description provided for @mailTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get mailTo;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @mailSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get mailSubject;

  /// No description provided for @mailBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get mailBody;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @ipOrHost.
  ///
  /// In en, this message translates to:
  /// **'IP or Host Name'**
  String get ipOrHost;

  /// No description provided for @rrType.
  ///
  /// In en, this message translates to:
  /// **'DNS Record Type'**
  String get rrType;

  /// No description provided for @macAddress.
  ///
  /// In en, this message translates to:
  /// **'MAC Address'**
  String get macAddress;

  /// No description provided for @vendorCode.
  ///
  /// In en, this message translates to:
  /// **'Vendor Code'**
  String get vendorCode;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name'**
  String get vendorName;

  /// No description provided for @tx.
  ///
  /// In en, this message translates to:
  /// **'Tx'**
  String get tx;

  /// No description provided for @rx.
  ///
  /// In en, this message translates to:
  /// **'Rx'**
  String get rx;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @checkPing.
  ///
  /// In en, this message translates to:
  /// **'Check PING'**
  String get checkPing;

  /// No description provided for @checkCertConfig.
  ///
  /// In en, this message translates to:
  /// **'Check Server Certificate'**
  String get checkCertConfig;

  /// No description provided for @runPing.
  ///
  /// In en, this message translates to:
  /// **'Run PING Checks'**
  String get runPing;

  /// No description provided for @runCert.
  ///
  /// In en, this message translates to:
  /// **'Run Cert Checks'**
  String get runCert;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @checkCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed Nodes'**
  String get checkCompletedCount;

  /// No description provided for @checkProblemCount.
  ///
  /// In en, this message translates to:
  /// **'Problem Nodes'**
  String get checkProblemCount;

  /// No description provided for @checkingNode.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checkingNode;

  /// No description provided for @checkFinished.
  ///
  /// In en, this message translates to:
  /// **'Check Finished'**
  String get checkFinished;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
