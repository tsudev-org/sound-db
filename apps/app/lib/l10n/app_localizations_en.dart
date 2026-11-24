// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navMeter => 'Meter';

  @override
  String get navAnalysis => 'Analysis';

  @override
  String get navTools => 'Tools';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get meterTitle => 'Sound level';

  @override
  String get meterReferenceTooltip => 'Common reference levels';

  @override
  String get meterNotCalibrated =>
      'Not calibrated: readings are estimates based on a typical microphone (error may be a few dB). Go to Settings > Calibration for accurate measurements.';

  @override
  String meterLevelSemantics(String name, String value) {
    return 'Sound level $name $value decibels';
  }

  @override
  String get meterZoneSafe => 'Safe level';

  @override
  String get meterZoneCaution => 'Caution level';

  @override
  String get meterZoneDanger => 'Harmful level';

  @override
  String get timeFast => 'Fast';

  @override
  String get timeSlow => 'Slow';

  @override
  String get timeImpulse => 'Impulse';

  @override
  String get meterLast2Min => 'Last 2 minutes';

  @override
  String get meterLeqHint => 'Equivalent continuous level of the whole session';

  @override
  String get meterPeakHint => 'Instantaneous peak';

  @override
  String get meterL10Hint => 'Level exceeded 10% of the time';

  @override
  String get meterL90Hint => 'Background noise';

  @override
  String get duration => 'Duration';

  @override
  String get resetSession => 'Reset session';

  @override
  String get saveSession => 'Save session';

  @override
  String get doseTitle => 'Noise exposure dose';

  @override
  String get doseNioshRule => '85 dBA / 8 hours, 3 dB exchange rate';

  @override
  String get doseOshaRule => '90 dBA / 8 hours, 5 dB exchange rate';

  @override
  String get doseNote =>
      'Computed on LAS since the session started. 100% is the exposure limit for one working day.';

  @override
  String get refTitle => 'Reference sound levels (dBA)';

  @override
  String get ref0 => 'Threshold of hearing';

  @override
  String get ref20 => 'Whisper, quiet bedroom';

  @override
  String get ref40 => 'Library, quiet office';

  @override
  String get ref60 => 'Normal conversation';

  @override
  String get ref70 => 'Vacuum cleaner, busy street';

  @override
  String get ref85 => 'Heavy traffic - 8-hour exposure threshold (NIOSH)';

  @override
  String get ref95 => 'Revving motorbike, power drill';

  @override
  String get ref110 => 'Concert, nightclub';

  @override
  String get ref120 => 'Ambulance siren up close - threshold of pain';

  @override
  String defaultSessionLabel(String time) {
    return 'Session $time';
  }

  @override
  String get sessionFallback => 'Session';

  @override
  String get sessionName => 'Session name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get sessionTooShort =>
      'The session is too short to save (at least 1 second is needed).';

  @override
  String savedLabel(String label) {
    return 'Saved \"$label\".';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'Account and sync';

  @override
  String get sectionCalibration => 'Calibration';

  @override
  String get micCalibration => 'Microphone calibration';

  @override
  String calibratedOffset(String offset) {
    return 'Calibrated · offset $offset';
  }

  @override
  String notCalibratedOffset(String offset) {
    return 'Not calibrated · using estimated offset $offset';
  }

  @override
  String get sectionTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get sectionMeasurement => 'Measurement';

  @override
  String get keepScreenOn => 'Keep the screen on while measuring';

  @override
  String get a4Reference => 'A4 reference frequency';

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get offlineMode => 'Fully offline mode';

  @override
  String get offlineModeHint =>
      'Blocks every outgoing connection, including sign-in and sync. Measuring keeps working fully.';

  @override
  String get audioNeverLeaves => 'Audio never leaves the device';

  @override
  String get audioNeverLeavesHint =>
      'Sound Db only processes audio in memory and never records it. The free version sends no measurement data to the internet; when syncing (TsuDEV Pro), only the measured numbers are sent.';

  @override
  String get sectionAbout => 'About';

  @override
  String get logoSemantics => 'Sound Db logo';

  @override
  String versionLine(String version) {
    return 'Version $version · A TsuDEV product';
  }

  @override
  String proUntil(String date) {
    return 'TsuDEV Pro until $date';
  }

  @override
  String get freePlan => 'Free version';

  @override
  String get proTileOn => 'Cloud sync and backup are on.';

  @override
  String get proTileOff =>
      'Data is stored only on this device. See the TsuDEV Pro plan to sync across devices, or support TsuDEV.';

  @override
  String get guestMode =>
      'You are using guest mode - every measuring feature is available.';

  @override
  String signInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get signInButton => 'Sign in with TsuDEV account';

  @override
  String get signInHint =>
      'Opens the system browser at tsudev.com (Google, GitHub or TsuDEV account). Sign in to use the TsuDEV Pro plan (cloud sync and backup) and badges; the free version needs no sign-in.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get autoSync => 'Sync automatically on launch and after saving';

  @override
  String get manageOnWeb => 'Manage devices and data on the web';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutWipe => 'Sign out and delete local data';

  @override
  String get signOutWipeHint =>
      'Deletes history, calibration and settings on this device. Synced copies (if any) remain in your account.';

  @override
  String get wipeConfirmTitle => 'Delete the data on this device?';

  @override
  String get wipeConfirmBody =>
      'Records that have not been synced will be lost permanently.';

  @override
  String get delete => 'Delete';

  @override
  String get calMethod94 => '94 dB @ 1 kHz calibrator';

  @override
  String get calMethod114 => '114 dB @ 1 kHz calibrator';

  @override
  String get calMethodReference =>
      'Against a reference meter (enter its reading)';

  @override
  String get micOpenFailed => 'Could not open the microphone.';

  @override
  String offsetApplied(String offset) {
    return 'Offset $offset applied.';
  }

  @override
  String currentOffset(String offset) {
    return 'Current offset: $offset';
  }

  @override
  String currentOffsetDefault(String offset) {
    return 'Current offset: $offset (default, not calibrated)';
  }

  @override
  String get calReferenceHowTo =>
      'Place the phone right next to the reference meter, both facing a steady noise source (fan, pink noise). Measure for 10 seconds, then enter the LAeq the reference meter shows for the same period.';

  @override
  String get calCalibratorHowTo =>
      'Fit the microphone into the calibrator coupler (or hold it tight against it if it does not fit), turn the calibrator on, keep still and tap Measure. The result uses the 10-second LZeq.';

  @override
  String get referenceLaeq => 'Reference meter LAeq (dB)';

  @override
  String measuringRemaining(String seconds) {
    return 'Measuring... $seconds s left';
  }

  @override
  String measureSeconds(String seconds) {
    return 'Measure $seconds s';
  }

  @override
  String measuredWithOld(String level) {
    return 'Measured: $level (with the old offset)';
  }

  @override
  String newOffset(String offset) {
    return 'New offset: $offset';
  }

  @override
  String get apply => 'Apply';

  @override
  String get manualOffset => 'Enter offset manually';

  @override
  String get offsetRange => 'The offset must be a number between 0 and 200 dB.';

  @override
  String get restoreDefault => 'Restore default (remove calibration)';

  @override
  String get analysisTitle => 'Frequency analysis';

  @override
  String get spectrumSettings => 'Spectrum settings';

  @override
  String get tabFft => 'FFT spectrum';

  @override
  String get tabSpectrogram => 'Spectrogram';

  @override
  String get tabOctave => 'Octave bands';

  @override
  String get dominantFrequency => 'Dominant frequency';

  @override
  String get peakLevel => 'Peak level';

  @override
  String get cursor => 'Cursor';

  @override
  String get tapChart => 'Tap the chart';

  @override
  String get peakHold => 'Peak hold';

  @override
  String get clearPeak => 'Clear peak';

  @override
  String fftInfo(String size, String window, String binHz, String weighting) {
    return 'FFT $size · $window · $binHz Hz/bin · $weighting weighting';
  }

  @override
  String spectrogramNote(String nyquist) {
    return 'Each row is one spectrum frame (newest on top); the horizontal axis is log frequency 20 Hz - $nyquist.';
  }

  @override
  String lowBandWarning(String bins) {
    return 'The lowest band covers only $bins FFT bins - increase the FFT size (Spectrum settings) for more accurate low bands.';
  }

  @override
  String bandNote(String weighting) {
    return 'Band levels (IEC 61260-1, base 10), $weighting weighting, from the averaged spectrum.';
  }

  @override
  String get fftSize => 'FFT size';

  @override
  String fftSamples(String n) {
    return '$n samples';
  }

  @override
  String get window => 'Window';

  @override
  String get windowRectangular => 'Rectangular';

  @override
  String displayRange(String min, String max) {
    return 'Display range: $min - $max dB';
  }

  @override
  String savedFile(String name) {
    return 'Saved $name';
  }

  @override
  String get deleteSessionTitle => 'Delete this session?';

  @override
  String get deleteSessionBody =>
      'The session will be deleted on this device and on every synced device.';

  @override
  String get actions => 'Actions';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get deleteSession => 'Delete session';

  @override
  String get doseNiosh => 'NIOSH dose';

  @override
  String get doseOsha => 'OSHA dose';

  @override
  String get laeqOverTime => 'LAeq over time';

  @override
  String get thirdOctaveAvg => 'Average 1/3 octave spectrum (LZeq)';

  @override
  String calOffsetAtMeasure(String offset) {
    return 'Calibration offset when measured: $offset';
  }

  @override
  String get historyTitle => 'Measurement history';

  @override
  String get reload => 'Reload';

  @override
  String get historyEmpty =>
      'No sessions yet. Tap \"Save session\" on the Meter screen to keep a result.';

  @override
  String get historyLoadFailed =>
      'Could not read the measurement history on this device. Your data is still there; tap Reload or update the app.';

  @override
  String get notSynced => ' · not synced';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get tabPitch => 'Frequency & pitch';

  @override
  String get tabGenerator => 'Signal generator';

  @override
  String get pitchNotDetected => 'No pitch detected';

  @override
  String noteSemantics(String note, String cents) {
    return 'Note $note, $cents cents off';
  }

  @override
  String get noPitchedSound => 'No pitched sound detected';

  @override
  String get deviation => 'Deviation';

  @override
  String get clarity => 'Clarity';

  @override
  String get dominantFft => 'Dominant frequency (FFT)';

  @override
  String get dominantLevel => 'Dominant level';

  @override
  String get a4Standard => 'A4 reference';

  @override
  String get pitchNote =>
      'Pitch uses the McLeod algorithm (NSDF) on 4096-sample frames, error < 1 cent for sounds with harmonics. The dominant frequency is the power centroid around the FFT peak - correct even for pure tones without harmonics.';

  @override
  String playFailed(String error) {
    return 'Could not play audio: $error';
  }

  @override
  String get generatorWarning =>
      'Start at a low volume. Very high frequencies or loud levels through headphones can damage your hearing and speakers.';

  @override
  String frequencyValue(String hz) {
    return 'Frequency: $hz';
  }

  @override
  String sweepNote(String seconds) {
    return 'Log sweep 20 Hz - 20 kHz over $seconds seconds, repeating.';
  }

  @override
  String signalVolume(String db) {
    return 'Signal volume: $db dBFS';
  }

  @override
  String get stopPlaying => 'Stop';

  @override
  String get play => 'Play';

  @override
  String get waveSine => 'Sine';

  @override
  String get waveSquare => 'Square';

  @override
  String get waveSawtooth => 'Sawtooth';

  @override
  String get waveTriangle => 'Triangle';

  @override
  String get waveWhite => 'White noise';

  @override
  String get wavePink => 'Pink noise';

  @override
  String get waveSweep => 'Frequency sweep';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get startMeasuring => 'Start measuring';

  @override
  String get error => 'Error';

  @override
  String get notice => 'Note';

  @override
  String get perPage => '/ page';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get errOfflineMode =>
      'Fully offline mode is on - turn it off in Settings to sign in.';

  @override
  String get errBrowser => 'Could not open the system browser.';

  @override
  String get errLoginCancelled => 'Sign-in was cancelled or denied.';

  @override
  String get errStateMismatch =>
      'The sign-in response does not match this session - blocked for safety.';

  @override
  String get errNoCode => 'The server returned no sign-in code.';

  @override
  String get errLoginTimeout =>
      'Waited 5 minutes for sign-in - please try again.';

  @override
  String get loopbackDone =>
      'Sign-in response received. You can close this tab and return to Sound Db.';

  @override
  String get errLoginFailed => 'Sign-in failed.';

  @override
  String errBadResponse(String status) {
    return 'The server returned invalid data (HTTP $status).';
  }

  @override
  String get errSignedOut => 'Not signed in.';

  @override
  String get syncRunning => 'Syncing...';

  @override
  String get syncFreePlan =>
      'Free version: data is stored only on this device. Syncing to the cloud requires TsuDEV Pro.';

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get syncNever => 'Never synced';

  @override
  String syncLast(String time) {
    return 'Synced at $time';
  }

  @override
  String syncRejected(String count) {
    return 'the server rejected $count records';
  }

  @override
  String get errMicPermission =>
      'Sound Db needs microphone permission to measure. Please grant it in the system settings.';

  @override
  String get errPcm16 => 'This device does not support 16-bit PCM recording.';

  @override
  String errMicOpen(String error) {
    return 'Could not open the microphone: $error';
  }

  @override
  String get windowFlatTop => 'Flat top';

  @override
  String get proStatus => 'Status';

  @override
  String proActiveLine(String date) {
    return 'TsuDEV Pro until $date: cloud sync and backup are on.';
  }

  @override
  String proExpiredLine(String date, String deleteDate) {
    return 'TsuDEV Pro expired on $date. Your cloud copy can be downloaded until $deleteDate.';
  }

  @override
  String get proFreeLine =>
      'Free version: every measuring feature is available; data is stored only on this device and never sent to the internet.';

  @override
  String get proFeaturesTitle => 'What Pro includes';

  @override
  String get proFeatures =>
      '• Sync measurement history and calibration profiles across devices on the same account.\n• Cloud backup, view and download on the web (sound.tsudev.com).\n• A Pro badge next to your account name. One plan shared by every TsuDEV product.';

  @override
  String get proPlaySoon =>
      'Buying TsuDEV Pro in Google Play is coming in the next update.';

  @override
  String get proRenewWeb => 'Renew on tsudev.com';

  @override
  String get proBuyWeb => 'Buy TsuDEV Pro on tsudev.com';

  @override
  String get supportTsudev => 'Support TsuDEV';

  @override
  String get proPayNote =>
      'Pay on tsudev.com with VietQR. After buying, reopen the app or tap Check again.';

  @override
  String get proCheckAgain => 'Check Pro plan again';

  @override
  String get historySearchHint => 'Search label, note, device';

  @override
  String get historyClearSearch => 'Clear search';

  @override
  String get historyRangeLabel => 'Time range';

  @override
  String get historyRangeAll => 'Any time';

  @override
  String get historyRange7d => 'Last 7 days';

  @override
  String get historyRange30d => 'Last month';

  @override
  String get historyRange1y => 'Last year';

  @override
  String get historyRangeCustom => 'Custom…';

  @override
  String historyNoMatchQuery(String query) {
    return 'No measurement sessions match \"$query\". Check the spelling, try other words or widen the time range.';
  }

  @override
  String get historyNoMatch =>
      'No measurement sessions in this time range. Try widening the range.';

  @override
  String historyResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching sessions',
      one: '1 matching session',
    );
    return '$_temp0';
  }

  @override
  String get openSettings => 'Open settings';

  @override
  String get signInWelcome => 'Welcome to Sound Db';

  @override
  String get signInTagline =>
      'Sign in to sync across devices (TsuDEV Pro) and get badges. Every measuring feature works without signing in.';

  @override
  String get signInWithTsudev => 'Continue with TsuDEV account';

  @override
  String get signInGuest => 'Continue without signing in';

  @override
  String get xdScanTitle => 'Scan to sign in';

  @override
  String get xdScanHint =>
      'On a computer that is signed in, open tsudev.com ⇒ Account ⇒ Sign in on phone.';

  @override
  String get xdNotTsudev => 'This QR code is not from tsudev.';

  @override
  String get xdApproveElsewhere =>
      'This code is for approving a new device. Scan it with a tsudev app that is signed in.';

  @override
  String get xdCameraDenied =>
      'Sound Db needs camera access to scan the code. You can still sign in with \"Continue with TsuDEV account\".';

  @override
  String get xdCameraError =>
      'Could not open the camera. You can still sign in with \"Continue with TsuDEV account\".';

  @override
  String get xdContinueTitle => 'Confirm on the page that just opened';

  @override
  String get xdContinueBody =>
      'Follow the tsudev.com page that just opened: wait for the computer to tap Allow, check it is your account, type the code shown on the computer. Then come back and tap Continue signing in.';

  @override
  String get xdContinue => 'Continue signing in';
}
