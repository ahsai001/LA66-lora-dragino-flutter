import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:hautomate/src/utils/util.dart';
import 'package:location/location.dart';

class SerialApp extends StatefulWidget {
  const SerialApp({super.key});

  @override
  _SerialAppState createState() => _SerialAppState();
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class _SerialAppState extends State<SerialApp> {
  var availablePorts = [];

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Port example'),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              for (final address in availablePorts)
                Builder(builder: (context) {
                  final port = SerialPort(address);
                  return ExpansionTile(
                    title: Text(address),
                    trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) {
                              return ConsolePage(address: address);
                            },
                          ));
                        },
                        label: const Text("Open Console")),
                    children: [
                      CardListTile('Description', port.description),
                      CardListTile('Transport', port.transport.toTransport()),
                      CardListTile('USB Bus', port.busNumber?.toPadded()),
                      CardListTile('USB Device', port.deviceNumber?.toPadded()),
                      CardListTile('Vendor ID', port.vendorId?.toHex()),
                      CardListTile('Product ID', port.productId?.toHex()),
                      CardListTile('Manufacturer', port.manufacturer),
                      CardListTile('Product Name', port.productName),
                      CardListTile('Serial Number', port.serialNumber),
                      CardListTile('MAC Address', port.macAddress),
                    ],
                  );
                }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: initPorts,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  const CardListTile(this.name, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}

class MessageData {
  final String name;
  final String message;

  const MessageData(this.name, this.message);
}

class ConsolePage extends StatefulWidget {
  final String address;
  const ConsolePage({super.key, required this.address});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  late SerialPort port;
  late SerialPortReader portReader;
  late TextEditingController messageTEC;
  List<MessageData> messages = [];
  StringBuffer buffer = StringBuffer();
  final scrollController = ScrollController();
  StreamSubscription<LocationData>? locSubscription;

  void logMessage(String name, String message) {
    setState(() {
      messages.add(MessageData(name, message));
    });
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    port = SerialPort(widget.address);
    portReader = SerialPortReader(port);

    if (port.openReadWrite()) {
      SerialPortConfig config = SerialPortConfig();
      config.baudRate = 9600;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.xonXoff = 0;
      config.rts = 1;
      config.cts = 0;
      config.dsr = 0;
      config.dtr = 1;
      port.config = config;
      //config.dispose();

      portReader.stream.listen((data) {
        buffer.write(String.fromCharCodes(data));
        if (buffer.toString().endsWith("\r\n")) {
          logMessage("received", buffer.toString());
          buffer.clear();
        }
      });
      sendATCommand("AT+NJS=?");
    } else {
      logMessage("info", "port not opened");
    }

    messageTEC = TextEditingController();

    locSubscription = getStreamPosition().listen(
      (location) {
        sendMessage('''
{
  "lat":${location.latitude},
  "long":${location.longitude}
}
''');
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    messageTEC.dispose();
    portReader.close();
    port.close();
    port.dispose();
    locSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemBuilder: (context, index) {
                MessageData messageData = messages[index];
                return CardListTile(messageData.name, messageData.message);
              },
              itemCount: messages.length,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageTEC,
                ),
              ),
              IconButton(
                  onPressed: () {
                    if (messageTEC.text.isNotEmpty && port.isOpen) {
                      sendMessage(messageTEC.text);
                      messageTEC.text = "";
                    } else {
                      logMessage("info", "message empty or port closed");
                    }
                  },
                  icon: const Icon(Icons.send))
            ],
          )
        ],
      ),
    );
  }

  Future<void> sendMessage(String message) async {
    logMessage("me", message);
    String base64String = base64Encode(message.codeUnits);
    final atCommand = "AT+SEND=0,2,${base64String.length},$base64String";
    await sendATCommand(atCommand);
  }

  Future<void> sendATCommand(String atCommand) async {
    logMessage("info", "at: $atCommand");
    try {
      port.write(
          Uint8List.fromList(hexStringToBytes("${strToASCII(atCommand)}0D0A")));
    } catch (e) {
      logMessage("info", e.toString());
    }
  }
}
