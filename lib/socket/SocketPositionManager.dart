import 'dart:io';
import 'dart:async';

import 'dart:typed_data';

class SocketPositionManager {
  static Socket socket;

  static final SocketPositionManager _singleton =
      SocketPositionManager._internal();

  factory SocketPositionManager() {
    return _singleton;
  }

  SocketPositionManager._internal();

  static Future configure(String url, int port) {
    Socket.connect(url, port).then((Socket sock) {
      socket = sock;
      socket.listen(dataHandler,
          onError: errorHandler, onDone: doneHandler, cancelOnError: false);
    }).catchError((AsyncError e) {
      print("Unable to connect: $e");
    });
    //Connect standard in to the socket
    stdin.listen(
        (data) => socket.write(new String.fromCharCodes(data).trim() + '\n'));
  }

  static void dataHandler(data) {
    print('get object from server !!');
    print(new String.fromCharCodes(data).trim());
  }

  static void sendMessage(Uint8List data) {
    socket.write(data);
  }

  static void errorHandler(error, StackTrace trace) {
    print(error);
  }

  static void doneHandler() {
    socket.close();
  }
}
