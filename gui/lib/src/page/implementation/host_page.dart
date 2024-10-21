import 'package:clipboard/clipboard.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluentUi show FluentIcons;
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:reboot_common/common.dart';
import 'package:reboot_launcher/main.dart';
import 'package:reboot_launcher/src/controller/dll_controller.dart';
import 'package:reboot_launcher/src/controller/game_controller.dart';
import 'package:reboot_launcher/src/controller/hosting_controller.dart';
import 'package:reboot_launcher/src/controller/settings_controller.dart';
import 'package:reboot_launcher/src/messenger/abstract/dialog.dart';
import 'package:reboot_launcher/src/messenger/abstract/info_bar.dart';
import 'package:reboot_launcher/src/messenger/abstract/overlay.dart';
import 'package:reboot_launcher/src/messenger/implementation/data.dart';
import 'package:reboot_launcher/src/page/abstract/page.dart';
import 'package:reboot_launcher/src/page/abstract/page_type.dart';
import 'package:reboot_launcher/src/util/translations.dart';
import 'package:reboot_launcher/src/widget/file_setting_tile.dart';
import 'package:reboot_launcher/src/widget/game_start_button.dart';
import 'package:reboot_launcher/src/widget/setting_tile.dart';
import 'package:reboot_launcher/src/widget/version_selector_tile.dart';

final GlobalKey<OverlayTargetState> hostVersionOverlayTargetKey = GlobalKey();
final GlobalKey<OverlayTargetState> hostInfoOverlayTargetKey = GlobalKey();
final GlobalKey<OverlayTargetState> hostInfoNameOverlayTargetKey = GlobalKey();
final GlobalKey<OverlayTargetState> hostInfoDescriptionOverlayTargetKey = GlobalKey();
final GlobalKey<OverlayTargetState> hostInfoPasswordOverlayTargetKey = GlobalKey();
final GlobalKey<OverlayTargetState> hostShareOverlayTargetKey = GlobalKey();
final GlobalKey<SettingTileState> hostInfoTileKey = GlobalKey();

class HostPage extends RebootPage {
  const HostPage({Key? key}) : super(key: key);

  @override
  String get name => translations.hostName;

  @override
  String get iconAsset => "assets/images/host.png";

  @override
  RebootPageType get type => RebootPageType.host;

  @override
  bool hasButton(String? pageName) => pageName == null;

  @override
  RebootPageState<HostPage> createState() => _HostingPageState();
}

class _HostingPageState extends RebootPageState<HostPage> {
  final GameController _gameController = Get.find<GameController>();
  final HostingController _hostingController = Get.find<HostingController>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  final DllController _dllController = Get.find<DllController>();

  late final RxBool _showPasswordTrailing = RxBool(_hostingController.password.text.isNotEmpty);

  @override
  void initState() {
    if(_hostingController.name.text.isEmpty) {
      _hostingController.name.text = translations.defaultServerName;
    }

    if(_hostingController.description.text.isEmpty) {
      _hostingController.description.text = translations.defaultServerDescription;
    }

    super.initState();
  }

  @override
  Widget get button => LaunchButton(
      host: true,
      startLabel: translations.startHosting,
      stopLabel: translations.stopHosting
  );

  @override
  List<Widget> get settings => [
    _information,
    buildVersionSelector(
        key: hostVersionOverlayTargetKey
    ),
    _options,
    _internalFiles,
    _share,
    _resetDefaults
  ];


  SettingTile get _information => SettingTile(
      key: hostInfoTileKey,
      icon: Icon(
          FluentIcons.info_24_regular
      ),
      title: Text(translations.hostGameServerName),
      subtitle: Text(translations.hostGameServerDescription),
      overlayKey: hostInfoOverlayTargetKey,
      children: [
        SettingTile(
            icon: Icon(
                FluentIcons.textbox_24_regular
            ),
            title: Text(translations.hostGameServerNameName),
            subtitle: Text(translations.hostGameServerNameDescription),
            content: OverlayTarget(
              key: hostInfoNameOverlayTargetKey,
              child: TextFormBox(
                  placeholder: translations.hostGameServerNameName,
                  controller: _hostingController.name,
                  focusNode: _hostingController.nameFocusNode,
                  onChanged: (_) => _updateServer()
              ),
            )
        ),
        SettingTile(
            icon: Icon(
                FluentIcons.text_description_24_regular
            ),
            title: Text(translations.hostGameServerDescriptionName),
            subtitle: Text(translations.hostGameServerDescriptionDescription),
            content: OverlayTarget(
              key: hostInfoDescriptionOverlayTargetKey,
              child: TextFormBox(
                  placeholder: translations.hostGameServerDescriptionName,
                  controller: _hostingController.description,
                  focusNode: _hostingController.descriptionFocusNode,
                  onChanged: (_) => _updateServer()
              ),
            )
        ),
        SettingTile(
            icon: Icon(
                FluentIcons.password_24_regular
            ),
            title: Text(translations.hostGameServerPasswordName),
            subtitle: Text(translations.hostGameServerDescriptionDescription),
            content: Obx(() => OverlayTarget(
              key: hostInfoPasswordOverlayTargetKey,
              child: TextFormBox(
                  placeholder: translations.hostGameServerPasswordName,
                  controller: _hostingController.password,
                  focusNode: _hostingController.passwordFocusNode,
                  autovalidateMode: AutovalidateMode.always,
                  obscureText: !_hostingController.showPassword.value,
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: (text) {
                    _showPasswordTrailing.value = text.isNotEmpty;
                    _updateServer();
                  },
                  suffix: Button(
                    onPressed: () => _hostingController.showPassword.value = !_hostingController.showPassword.value,
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(const CircleBorder()),
                        backgroundColor: WidgetStateProperty.all(Colors.transparent)
                    ),
                    child: Icon(
                        _hostingController.showPassword.value ? FluentIcons.eye_off_24_filled : FluentIcons.eye_24_filled,
                        color: _showPasswordTrailing.value ? null : Colors.transparent
                    ),
                  )
              ),
            ))
        ),
        SettingTile(
            icon: Icon(
                FluentIcons.eye_24_regular
            ),
            title: Text(translations.hostGameServerDiscoverableName),
            subtitle: Text(translations.hostGameServerDiscoverableDescription),
            contentWidth: null,
            content: Obx(() => Row(
              children: [
  Obx(() => Text(
                    _hostingController.discoverable.value ? translations.on : translations.off
                )),
                const SizedBox(
                    width: 16.0
                ),
                ToggleSwitch(
                    checked: _hostingController.discoverable(),
                    onChanged: (value) async {
                      _hostingController.discoverable.value = value;
                      await _updateServer();
                    }
                ),
              ],
            ))
        )
      ]
  );

  SettingTile get _options => SettingTile(
    icon: Icon(
        FluentIcons.options_24_regular
    ),
    title: Text(translations.settingsServerOptionsName),
    subtitle: Text(translations.settingsServerOptionsSubtitle),
    children: [
      SettingTile(
          icon: Icon(
              FluentIcons.options_24_regular
          ),
          title: Text(translations.settingsClientArgsName),
          subtitle: Text(translations.settingsClientArgsDescription),
          content: TextFormBox(
            placeholder: translations.settingsClientArgsPlaceholder,
            controller: _hostingController.customLaunchArgs,
          )
      ),
      SettingTile(
        icon: Icon(
            FluentIcons.window_console_20_regular
        ),
        title: Text(translations.gameServerTypeName),
        subtitle: Text(translations.gameServerTypeDescription),
        content: Obx(() => DropDownButton(
            onOpen: () => inDialog = true,
            onClose: () => inDialog = false,
            leading: Text(_hostingController.type.value.translatedName),
            items: GameServerType.values.map((entry) => MenuFlyoutItem(
                text: Text(entry.translatedName),
                onPressed: () => _hostingController.type.value = entry
            )).toList()
        )),
      ),
      SettingTile(
        icon: Icon(
            FluentIcons.arrow_reset_24_regular
        ),
        title: Text(translations.hostAutomaticRestartName),
        subtitle: Text(translations.hostAutomaticRestartDescription),
        contentWidth: null,
        content: Row(
          children: [
            Obx(() => Text(
                _hostingController.autoRestart.value ? translations.on : translations.off
            )),
            const SizedBox(
                width: 16.0
            ),
            Obx(() => ToggleSwitch(
                checked: _hostingController.autoRestart.value,
                onChanged: (value) => _hostingController.autoRestart.value = value
            )),
          ],
        ),
      ),
      SettingTile(
          icon: Icon(
              fluentUi.FluentIcons.number_field
          ),
          title: Text(translations.settingsServerPortName),
          subtitle: Text(translations.settingsServerPortDescription),
          contentWidth: 64,
          content: TextFormBox(
              placeholder:  translations.settingsServerPortName,
              controller: _dllController.gameServerPort,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ]
          )
      )
    ],
  );

  SettingTile get _internalFiles => SettingTile(
    icon: Icon(
        FluentIcons.archive_settings_24_regular
    ),
    title: Text(translations.settingsServerName),
    subtitle: Text(translations.settingsServerSubtitle),
    children: [
      _internalFilesServerType,
      _internalFilesUpdateTimer,
      _internalFilesOldServerSource,
      _internalFilesNewServerSource,
    ],
  );

  Widget get _internalFilesServerType => SettingTile(
      icon: Icon(
          FluentIcons.games_24_regular
      ),
      title: Text(translations.settingsServerTypeName),
      subtitle: Text(translations.settingsServerTypeDescription),
      contentWidth: SettingTile.kDefaultContentWidth + 30,
      content: Obx(() => DropDownButton(
          onOpen: () => inDialog = true,
          onClose: () => inDialog = false,
          leading: Text(_dllController.customGameServer.value ? translations.settingsServerTypeCustomName : translations.settingsServerTypeEmbeddedName),
          items: {
            false: translations.settingsServerTypeEmbeddedName,
            true: translations.settingsServerTypeCustomName
          }.entries.map((entry) => MenuFlyoutItem(
              text: Text(entry.value),
              onPressed: () {
                final oldValue = _dllController.customGameServer.value;
                if(oldValue == entry.key) {
                  return;
                }

                _dllController.customGameServer.value = entry.key;
                _dllController.infoBarEntry?.close();
                if(!entry.key) {
                  _dllController.updateGameServerDll(
                      force: true
                  );
                }
              }
          )).toList()
      ))
  );

  Widget get _internalFilesOldServerSource => Obx(() {
    if(!_dllController.customGameServer.value) {
      return SettingTile(
          icon: Icon(
              FluentIcons.globe_24_regular
          ),
          title: Text(translations.settingsServerOldMirrorName),
          subtitle: Text(translations.settingsServerMirrorDescription),
          contentWidth: SettingTile.kDefaultContentWidth + 30,
          content: Row(
            children: [
              Expanded(
                child: TextFormBox(
                  placeholder:  translations.settingsServerMirrorPlaceholder,
                  controller: _dllController.beforeS20Mirror,
                  onChanged: (value) {
                    if(Uri.tryParse(value) != null) {
                      _dllController.updateGameServerDll(force: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Button(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero)
                  ),
                  onPressed: () => _dllController.updateGameServerDll(force: true),
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(
                        FluentIcons.arrow_download_24_regular
                    ),
                  )
              ),
              const SizedBox(width: 8.0),
              Button(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero)
                  ),
                  onPressed: () {
                    _dllController.beforeS20Mirror.text = kRebootBelowS20DownloadUrl;
                    _dllController.updateGameServerDll(force: true);
                  },
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(
                        FluentIcons.arrow_reset_24_regular
                    ),
                  )
              )
            ],
          )
      );
    }else {
      return createFileSetting(
          title: translations.settingsOldServerFileName,
          description: translations.settingsServerFileDescription,
          controller: _dllController.gameServerDll,
          onReset: () {
            final path = _dllController.getDefaultDllPath(InjectableDll.reboot);
            _dllController.gameServerDll.text = path;
            _dllController.downloadCriticalDllInteractive(path);
          }
      );
    }
  });

  Widget get _internalFilesNewServerSource => Obx(() {
    if(!_dllController.customGameServer.value) {
      return SettingTile(
          icon: Icon(
              FluentIcons.globe_24_regular
          ),
          title: Text(translations.settingsServerNewMirrorName),
          subtitle: Text(translations.settingsServerMirrorDescription),
          contentWidth: SettingTile.kDefaultContentWidth + 30,
          content: Row(
            children: [
              Expanded(
                child: TextFormBox(
                  placeholder: translations.settingsServerMirrorPlaceholder,
                  controller: _dllController.aboveS20Mirror,
                  onChanged: (value) {
                    if(Uri.tryParse(value) != null) {
                      _dllController.updateGameServerDll(force: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Button(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero)
                  ),
                  onPressed: () => _dllController.updateGameServerDll(force: true),
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(
                        FluentIcons.arrow_download_24_regular
                    ),
                  )
              ),
              const SizedBox(width: 8.0),
              Button(
                  style: ButtonStyle(
                      padding: WidgetStateProperty.all(EdgeInsets.zero)
                  ),
                  onPressed: () {
                    _dllController.aboveS20Mirror.text = kRebootBelowS20DownloadUrl;
                    _dllController.updateGameServerDll(force: true);
                  },
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(
                        FluentIcons.arrow_reset_24_regular
                    ),
                  )
              )
            ],
          )
      );
    }else {
      return createFileSetting(
          title: translations.settingsNewServerFileName,
          description: translations.settingsServerFileDescription,
          controller: _dllController.gameServerDll,
          onReset: () {
            final path = _dllController.getDefaultDllPath(InjectableDll.reboot);
            _dllController.gameServerDll.text = path;
            _dllController.downloadCriticalDllInteractive(path);
          }
      );
    }
  });

  Widget get _internalFilesUpdateTimer => Obx(() {
    if(_dllController.customGameServer.value) {
      return const SizedBox.shrink();
    }

    return SettingTile(
        icon: Icon(
            FluentIcons.timer_24_regular
        ),
        title: Text(translations.settingsServerTimerName),
        subtitle: Text(translations.settingsServerTimerSubtitle),
        contentWidth: SettingTile.kDefaultContentWidth + 30,
        content: Obx(() => DropDownButton(
            onOpen: () => inDialog = true,
            onClose: () => inDialog = false,
            leading: Text(_dllController.timer.value.text),
            items: UpdateTimer.values.map((entry) => MenuFlyoutItem(
                text: Text(entry.text),
                onPressed: () {
                  _dllController.timer.value = entry;
                  _dllController.infoBarEntry?.close();
                  _dllController.updateGameServerDll(
                      force: true
                  );
                }
            )).toList()
        ))
    );
  });

  SettingTile get _share => SettingTile(
    icon: Icon(
        FluentIcons.link_24_regular
    ),
    title: Text(translations.hostShareName),
    subtitle: Text(translations.hostShareDescription),
    overlayKey: hostShareOverlayTargetKey,
    children: [
      SettingTile(
          icon: Icon(
              FluentIcons.link_24_regular
          ),
          title: Text(translations.hostShareLinkName),
          subtitle: Text(translations.hostShareLinkDescription),
          content: Button(
            onPressed: () async {
              FlutterClipboard.controlC("$kCustomUrlSchema://${_hostingController.uuid}");
              _showCopiedLink();
            },
            child: Text(translations.hostShareLinkContent),
          )
      ),
      SettingTile(
          icon: Icon(
              FluentIcons.globe_24_regular
          ),
          title: Text(translations.hostShareIpName),
          subtitle: Text(translations.hostShareIpDescription),
          content: Button(
            onPressed: () async {
              InfoBarEntry? entry;
              try {
                entry = _showCopyingIp();
                final ip = await Ipify.ipv4();
                entry.close();
                FlutterClipboard.controlC(ip);
                _showCopiedIp();
              }catch(error) {
                entry?.close();
                _showCannotCopyIp(error);
              }
            },
            child: Text(translations.hostShareIpContent),
          )
      )
    ],
  );

  SettingTile get _resetDefaults => SettingTile(
      icon: Icon(
          FluentIcons.arrow_reset_24_regular
      ),
      title: Text(translations.hostResetName),
      subtitle: Text(translations.hostResetDescription),
      content: Button(
        onPressed: () => showResetDialog(() {
          _hostingController.reset();
          _dllController.resetServer();
        }),
        child: Text(translations.hostResetContent),
      )
  );

  Future<void> _updateServer() async {
    if(!_hostingController.published()) {
      return;
    }

    try {
      _hostingController.publishServer(
          _gameController.username.text,
          _hostingController.instance.value!.versionName
      );
    } catch(error) {
      _showCannotUpdateGameServer(error);
    }
  }

  void _showCopiedLink() => showRebootInfoBar(
      translations.hostShareLinkMessageSuccess,
      severity: InfoBarSeverity.success
  );

  InfoBarEntry _showCopyingIp() => showRebootInfoBar(
      translations.hostShareIpMessageLoading,
      loading: true,
      duration: null
  );

  void _showCopiedIp() => showRebootInfoBar(
      translations.hostShareIpMessageSuccess,
      severity: InfoBarSeverity.success
  );

  void _showCannotCopyIp(Object error) => showRebootInfoBar(
      translations.hostShareIpMessageError(error.toString()),
      severity: InfoBarSeverity.error,
      duration: infoBarLongDuration
  );

  void _showCannotUpdateGameServer(Object error) => showRebootInfoBar(
      translations.cannotUpdateGameServer(error.toString()),
      severity: InfoBarSeverity.success,
      duration: infoBarLongDuration
  );
}

extension _UpdateTimerExtension on UpdateTimer {
  String get text {
    if (this == UpdateTimer.never) {
      return translations.updateGameServerDllNever;
    }

    return translations.updateGameServerDllEvery(name);
  }
}