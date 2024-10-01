import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hautomate/src/utils/util.dart';
import 'package:location/location.dart';
import 'package:usb_serial/usb_serial.dart';

class SerialApp extends StatefulWidget {
  const SerialApp({super.key});

  @override
  _SerialAppState createState() => _SerialAppState();
}

class _SerialAppState extends State<SerialApp> {
  List<UsbDevice> devices = [];

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    UsbSerial.listDevices().then(
      (usbDevices) {
        setState(() {
          devices = usbDevices;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LA66 Device'),
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              for (final device in devices)
                Builder(builder: (context) {
                  return ExpansionTile(
                    title: Text(device.deviceName),
                    trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) {
                              return ConsolePage(device: device);
                            },
                          ));
                        },
                        label: const Text("Open Console")),
                    children: [
                      CardListTile('PID', device.pid.toString()),
                      CardListTile('Vendor ID', device.vid.toString()),
                      CardListTile('Device ID', device.deviceId.toString()),
                      CardListTile(
                          'Manufacturer Name', device.manufacturerName),
                      CardListTile('Device Name', device.deviceName),
                      CardListTile('Serial Number', device.serial),
                      CardListTile('Product Name', device.productName),
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
  final UsbDevice device;
  const ConsolePage({super.key, required this.device});

  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  UsbPort? port;
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
    widget.device.create().then(
      (port) {
        if (port == null) {
          logMessage("info", "usb port not created");
        }
        port?.open().then(
          (opened) {
            if (opened) {
              setState(() {
                this.port = port;
                this.port?.setPortParameters(9600, UsbPort.DATABITS_8,
                    UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
                this.port?.setRTS(false);
                this.port?.setDTR(false);
                this.port?.setFlowControl(UsbPort.FLOW_CONTROL_OFF);

                this.port?.inputStream?.listen((Uint8List event) {
                  buffer.write(String.fromCharCodes(event));
                  if (buffer.toString().endsWith("\r\n")) {
                    logMessage("received", buffer.toString());
                    buffer.clear();
                  }
                });

                sendATCommand("AT+NJS=?");
              });
            } else {
              logMessage("info", "usb port not opened");
            }
          },
        );
      },
    );

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
    port?.close();
    locSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
                    decoration:
                        const InputDecoration(hintText: "Masukkan  pesan anda"),
                    controller: messageTEC,
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      if (messageTEC.text.isNotEmpty && port != null) {
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
      await port?.write(
          Uint8List.fromList(hexStringToBytes("${strToASCII(atCommand)}0D0A")));
    } catch (e) {
      logMessage("info", e.toString());
    }
  }
}
