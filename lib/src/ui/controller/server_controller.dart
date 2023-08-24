import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:reboot_launcher/src/model/server_type.dart';
import 'package:reboot_launcher/src/util/server.dart';

class ServerController extends GetxController {
  static const String _kDefaultServerHost = "127.0.0.1";
  static const String _kDefaultServerPort = "3551";

  late final GetStorage _storage;
  late final TextEditingController host;
  late final TextEditingController port;
  late final Rx<ServerType> type;
  late RxBool started;
  late RxBool detached;
  HttpServer? remoteServer;

  ServerController() {
    _storage = GetStorage("reboot_server");
    started = RxBool(false);
    type = Rx(ServerType.values.elementAt(_storage.read("type") ?? 0));
    type.listen((value) {
      host.text = _readHost();
      port.text = _readPort();
      _storage.write("type", value.index);
      if(!started.value) {
        return;
      }

      stop();
    });
    host = TextEditingController(text: _readHost());
    host.addListener(() => _storage.write("${type.value.id}_host", host.text));
    port = TextEditingController(text: _readPort());
    port.addListener(() => _storage.write("${type.value.id}_port", port.text));
    detached = RxBool(_storage.read("detached") ?? false);
    detached.listen((value) => _storage.write("detached", value));
  }

  void reset() async {
    await stop();
    type.value = ServerType.values.elementAt(0);
    for(var type in ServerType.values){
      _storage.write("${type.id}_host", null);
      _storage.write("${type.id}_port", null);
    }

    host.text = type.value != ServerType.remote ? _kDefaultServerHost : "";
    port.text = _kDefaultServerPort;
    detached.value = false;
  }

  String _readHost() {
    String? value = _storage.read("${type.value.id}_host");
    return value != null && value.isNotEmpty ? value
        : type.value != ServerType.remote ? _kDefaultServerHost : "";
  }

  String _readPort() {
    return _storage.read("${type.value.id}_port") ?? _kDefaultServerPort;
  }

  Future<bool> stop() async {
    started.value = false;
    try{
      switch(type()){
        case ServerType.embedded:
          stopServer();
          break;
        case ServerType.remote:
          await remoteServer?.close(force: true);
          remoteServer = null;
          break;
        case ServerType.local:
          break;
      }
      return true;
    }catch(_){
      started.value = true;
      return false;
    }
  }
}