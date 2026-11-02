import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Speed presets as declared in the spec (0.25–5x)
const List<double> kSpeedPresets = [
  0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0, 5.0
];

// iOS AVPlayer reliably supports up to 2x; clamp above that on iOS.
const double kIosMaxSpeed = 2.0;

/// A ChangeNotifier that owns all playback logic for a single video file.
/// The UI only reads state from here; it never calls VideoPlayerController
/// directly.
class VideoPlayerNotifier extends ChangeNotifier {
  final File file;

  VideoPlayerController? _vpc;
  VideoPlayerController? get controller => _vpc;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _speed = 1.0;
  double get speed => _speed;

  double _volume = 1.0;
  double get volume => _volume;

  bool _muted = false;
  bool get muted => _muted;

  bool _controlsVisible = true;
  bool get controlsVisible => _controlsVisible;

  bool _isFullscreen = false;
  bool get isFullscreen => _isFullscreen;

  bool _isLongPressing = false;
  double _speedBeforeLongPress = 1.0;

  Timer? _hideControlsTimer;
  Timer? _positionTimer;

  // iOS capability flag
  final bool _isIos = Platform.isIOS;

  VideoPlayerNotifier({required this.file});

  /// Initialise the player and restore last position + speed.
  Future<void> initialize() async {
    _vpc = VideoPlayerController.file(file);
    await _vpc!.initialize();
    _duration = _vpc!.value.duration;

    // Restore saved speed
    final prefs = await SharedPreferences.getInstance();
    final savedSpeed = prefs.getDouble('vp_last_speed') ?? 1.0;
    await _applySpeed(savedSpeed);

    // Restore resume position for this specific file
    final savedMs = prefs.getInt('vp_pos_${file.path}') ?? 0;
    if (savedMs > 0 && savedMs < _duration.inMilliseconds - 2000) {
      await _vpc!.seekTo(Duration(milliseconds: savedMs));
    }

    _vpc!.addListener(_onVpcUpdate);
    _initialized = true;
    notifyListeners();

    _startPositionTimer();
    await WakelockPlus.enable();
    play();
  }

  void _onVpcUpdate() {
    final v = _vpc!.value;
    if (v.isPlaying != _isPlaying) {
      _isPlaying = v.isPlaying;
      if (_isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      notifyListeners();
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (_vpc == null) return;
      final pos = _vpc!.value.position;
      if (pos != _position) {
        _position = pos;
        notifyListeners();
        // Persist resume position
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('vp_pos_${file.path}', pos.inMilliseconds);
      }
    });
  }

  Future<void> play() async {
    await _vpc?.play();
    _isPlaying = true;
    _resetHideControlsTimer();
    notifyListeners();
  }

  Future<void> pause() async {
    await _vpc?.pause();
    _isPlaying = false;
    _showControls();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekBy(Duration delta) async {
    if (_vpc == null) return;
    Duration newPos = _position + delta;
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > _duration) newPos = _duration;
    await _vpc!.seekTo(newPos);
    _position = newPos;
    notifyListeners();
  }

  Future<void> seekTo(Duration pos) async {
    await _vpc?.seekTo(pos);
    _position = pos;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    final clamped = _isIos ? speed.clamp(0.25, kIosMaxSpeed) : speed;
    await _applySpeed(clamped);
    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('vp_last_speed', clamped);
    notifyListeners();
  }

  Future<void> _applySpeed(double speed) async {
    _speed = speed;
    await _vpc?.setPlaybackSpeed(speed);
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    _muted = _volume == 0;
    await _vpc?.setVolume(_muted ? 0 : _volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    await _vpc?.setVolume(_muted ? 0 : _volume);
    notifyListeners();
  }

  // Long-press: temporarily play at 2x
  Future<void> beginLongPress() async {
    if (_isLongPressing) return;
    _isLongPressing = true;
    _speedBeforeLongPress = _speed;
    await _applySpeed(2.0);
    notifyListeners();
  }

  Future<void> endLongPress() async {
    if (!_isLongPressing) return;
    _isLongPressing = false;
    await _applySpeed(_speedBeforeLongPress);
    notifyListeners();
  }

  bool get isLongPressing => _isLongPressing;

  // Controls visibility
  void toggleControls() {
    if (_controlsVisible) {
      _hideControls();
    } else {
      _showControls();
    }
  }

  void _showControls() {
    _controlsVisible = true;
    notifyListeners();
    _resetHideControlsTimer();
  }

  void _hideControls() {
    _controlsVisible = false;
    _hideControlsTimer?.cancel();
    notifyListeners();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_isPlaying) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        _controlsVisible = false;
        notifyListeners();
      });
    }
  }

  // Fullscreen / orientation
  Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    if (_isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    notifyListeners();
  }

  bool get isIos => _isIos;

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _positionTimer?.cancel();
    _vpc?.removeListener(_onVpcUpdate);
    _vpc?.dispose();
    WakelockPlus.disable();
    // Restore orientation & UI
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
