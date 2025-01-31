// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of flutter_blue_plus;

class BluetoothDescriptor {
  static final Guid cccd = Guid("00002902-0000-1000-8000-00805f9b34fb");

  final Guid descriptorUuid;
  final DeviceIdentifier remoteId;
  final Guid serviceUuid;
  final Guid characteristicUuid;

  @Deprecated('Use deviceId instead')
  DeviceIdentifier get deviceId => remoteId;

  @Deprecated('Use descriptorUuid instead')
  Guid get uuid => descriptorUuid;

  final _BehaviorSubject<List<int>> _value;

  Stream<List<int>> get value => _value.stream;

  List<int> get lastValue => _value.latestValue;

  final _Mutex _readWriteMutex = _Mutex();

  BluetoothDescriptor.fromProto(BmBluetoothDescriptor p)
      : descriptorUuid = Guid(p.descriptorUuid),
        remoteId = DeviceIdentifier(p.remoteId),
        serviceUuid = Guid(p.serviceUuid),
        characteristicUuid = Guid(p.characteristicUuid),
        _value = _BehaviorSubject(p.value);

  /// Retrieves the value of a specified descriptor
  Future<List<int>> read({int timeout = 15}) async {
    List<int> readValue = [];

    // Only allow a single read or write operation
    // at a time, to prevent race conditions.
    await _readWriteMutex.synchronized(() async {
      var request = BmReadDescriptorRequest(
        remoteId: remoteId.toString(),
        descriptorUuid: descriptorUuid.toString(),
        characteristicUuid: characteristicUuid.toString(),
        secondaryServiceUuid: null,
        serviceUuid: serviceUuid.toString(),
      );

      Stream<BmReadDescriptorResponse> responseStream = FlutterBluePlus
          .instance._methodStream
          .where((m) => m.method == "ReadDescriptorResponse")
          .map((m) => m.arguments)
          .map((buffer) => BmReadDescriptorResponse.fromMap(buffer))
          .where((p) =>
              (p.request.remoteId == request.remoteId) &&
              (p.request.descriptorUuid == request.descriptorUuid) &&
              (p.request.characteristicUuid == request.characteristicUuid) &&
              (p.request.serviceUuid == request.serviceUuid));

      // Start listening now, before invokeMethod, to ensure we don't miss the response
      Future<BmReadDescriptorResponse> futureResponse = responseStream.first;

      await FlutterBluePlus.instance._channel
          .invokeMethod('readDescriptor', request.toMap());

      BmReadDescriptorResponse response = await futureResponse.timeout(Duration(seconds: timeout));

      if (!response.success) {
        throw FlutterBluePlusException("readDescriptorFail", response.errorCode, response.errorString);
      }

      readValue = response.value;

      _value.add(readValue);
    }).catchError((e, stacktrace) {
      throw Exception("$e $stacktrace");
    });

    return readValue;
  }

  /// Writes the value of a descriptor
  Future<void> write(List<int> value, {int timeout = 15}) async {
    // Only allow a single read or write operation
    // at a time, to prevent race conditions.
    await _readWriteMutex.synchronized(() async {
      var request = BmWriteDescriptorRequest(
        remoteId: remoteId.toString(),
        descriptorUuid: descriptorUuid.toString(),
        characteristicUuid: characteristicUuid.toString(),
        serviceUuid: serviceUuid.toString(),
        secondaryServiceUuid: null,
        value: value,
      );

      Stream<BmWriteDescriptorResponse> responseStream = FlutterBluePlus
          .instance._methodStream
          .where((m) => m.method == "WriteDescriptorResponse")
          .map((m) => m.arguments)
          .map((buffer) => BmWriteDescriptorResponse.fromMap(buffer))
          .where((p) =>
              (p.request.remoteId == request.remoteId) &&
              (p.request.descriptorUuid == request.descriptorUuid) &&
              (p.request.characteristicUuid == request.characteristicUuid) &&
              (p.request.serviceUuid == request.serviceUuid));

      // Start listening now, before invokeMethod, to ensure we don't miss the response
      Future<BmWriteDescriptorResponse> futureResponse = responseStream.first;

      await FlutterBluePlus.instance._channel
          .invokeMethod('writeDescriptor', request.toMap());

      BmWriteDescriptorResponse response = await futureResponse.timeout(Duration(seconds: timeout));

      if (!response.success) {
        throw FlutterBluePlusException("readDescriptorFail", response.errorCode, response.errorString);
      }

      _value.add(value);
    }).catchError((e, stacktrace) {
      throw Exception("$e $stacktrace");
    });

    return Future.value();
  }

  @override
  String toString() {
    return 'BluetoothDescriptor{'
        'descriptorUuid: $descriptorUuid, '
        'remoteId: $remoteId, '
        'serviceUuid: $serviceUuid, '
        'characteristicUuid: $characteristicUuid, '
        'value: ${_value.value}'
        '}';
  }
}
