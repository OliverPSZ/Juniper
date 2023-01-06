// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_example/main.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:math' as math;
import 'dart:convert';

int status_flag = 0;
String notification = ' ';
String funfact = ' ';
String dropdownvalue = 'Test Mode';
int ff_counter = 0;
int f_counter = 0;

// List of items in our dropdown menu
var items = [
  'Test Mode',
  'Level 1',
  'Level 2',
  'Level 3',
  'Level 4',
];

var funfacts = [
  'Add 240 to 470 ml to mint plants each watering',
  'Mint grows best when it’s partially shaded',
  'Mint plants originate in the mediterranean region',
  'US produces 70% of the worlds peppermint and spearmint',
  'There are over 600 types of mint plants',
];

MaterialColor GUIcolor = Colors.lightGreen;
MaterialColor GUIcolort = Colors.lightGreen;
MaterialColor GUIcolorh = Colors.lightGreen;
MaterialColor GUIcolorl = Colors.lightGreen;

List<double> sftemp = [0,0,0,0,0,0,0,0,0,0];
List<double> sfhum = [0,0,0,0,0,0,0,0,0,0];
List<double> sflight = [0,0,0,0,0,0,0,0,0,0];

late BluetoothDevice juniperdevice;

double count = 10;

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: ElevatedButton(
        child: Text('CONNECT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(context, 'Manufacturer Data',
            getNiceManufacturerData(result.advertisementData.manufacturerData)),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData)),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (service.uuid.toString().toUpperCase().substring(4, 8) == 'A123') {
      return Center(
        child:
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
          characteristicTiles

        ),
      );
    } else {
        return Center(
        );
      }
    }
  }


class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;

  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  CharacteristicTile(
      {Key? key,
      required this.characteristic,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed,
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;


        Uint8List intBytes = Uint8List.fromList(value!.toList());
        List<double> floatList = intBytes.buffer.asFloat32List();

        if (floatList.length == 0){
          sftemp[9] = sftemp[9];
          sfhum[9] = sftemp[9];
          sflight[9] = sftemp[9];

        }else if(characteristic.uuid.toString().substring(4,8) == "2a19"){
          sftemp[0] = sftemp[1];
          sftemp[1] = sftemp[2];
          sftemp[2] = sftemp[3];
          sftemp[3] = sftemp[4];
          sftemp[4] = sftemp[5];
          sftemp[5] = sftemp[6];
          sftemp[6] = sftemp[7];
          sftemp[7] = sftemp[8];
          sftemp[8] = sftemp[9];
          sftemp[9] = floatList[0];


        }else if(characteristic.uuid.toString().substring(4,8) == "2a20") {
          sfhum[0] = sfhum[1];
          sfhum[1] = sfhum[2];
          sfhum[2] = sfhum[3];
          sfhum[3] = sfhum[4];
          sfhum[4] = sfhum[5];
          sfhum[5] = sfhum[6];
          sfhum[6] = sfhum[7];
          sfhum[7] = sfhum[8];
          sfhum[8] = sfhum[9];
          sfhum[9] = floatList[0];

        }else{
          sflight[0] = sflight[1];
          sflight[1] = sflight[2];
          sflight[2] = sflight[3];
          sflight[3] = sflight[4];
          sflight[4] = sflight[5];
          sflight[5] = sflight[6];
          sflight[6] = sflight[7];
          sflight[7] = sflight[8];
          sflight[8] = sflight[9];
          sflight[9] = floatList[0];
        }

        count = count+1/3;
        status_flag = 0;

        notification = 'Ambient temperature:\n';
        if(sftemp[9]>21.0){
          notification = notification+'Too high (Max 21 °C)\n';
          status_flag++;
          GUIcolort = Colors.orange;
        }else if (sftemp[9]<-28.0){
          notification = notification+'Too low (Min -28 °C)\n';
          status_flag++;
          GUIcolort = Colors.orange;
        }else{
          notification = notification+'Correct for your plant\n';
          GUIcolort = Colors.lightGreen;
        }

        notification = notification+'\nSoil Humidity:\n';
        if(sfhum[9]>45.0){
          notification = notification+'Too high (Max 45 %)\n';
          status_flag++;
          GUIcolorh = Colors.orange;
        }else if (sfhum[9]<35.0){
          notification = notification+'Too low (Min 35 %)\n';
          status_flag++;
          GUIcolorh = Colors.orange;
        }else{
          notification = notification+'Correct for your plant\n';
          GUIcolorh = Colors.lightGreen;
        }

        notification = notification+'\nAmbient light:\n';
        if(sflight[9]>3500.0){
          notification = notification+'Too high (Max 3500 lux)';
          status_flag++;
          GUIcolorl = Colors.orange;
        }else if (sflight[9]<1500.0){
          notification = notification+'Too low (Min 1500 lux)';
          status_flag++;
          GUIcolorl = Colors.orange;
        }else{
          notification = notification+'Correct for your plant';
          GUIcolorl = Colors.lightGreen;
        }

        if (status_flag>0){
          GUIcolor = Colors.orange;
        }else{
          GUIcolor = Colors.lightGreen;
        }

        f_counter++;

        if (f_counter%30==0){
          ff_counter++;
        }
        if (ff_counter>3){
          ff_counter = 0;
        }

        funfact = 'Fun Fact:\n'+funfacts[ff_counter];

          return Column(
            children: [
              if (characteristic.uuid.toString().substring(4,8) == "2a19")
                Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(
                    width: 5,
                  ),Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Container(
                    decoration: new BoxDecoration(
                        border: Border.all(width: 4,color: GUIcolor),
                        color: Colors.white,
                        shape: BoxShape.circle
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[

                          if (status_flag == 0) Image.asset(
                            'assets/HappyBasil.png',
                            height: 120,
                            fit: BoxFit.cover,
                          ) else Image.asset(
                            'assets/SadBasil.png',
                            height: 120,
                            fit: BoxFit.cover,
                          ),

                        ]
                    )

                ),

                      Image.asset('assets/MINT.png', fit: BoxFit.contain,
                          height: 30)
                ]),
                        SizedBox(
                   width: 15,
                ),
                Card(
                  child: Container(
                    decoration: new BoxDecoration(
                      border: Border.all(color: GUIcolor),
                      borderRadius: new BorderRadius.circular(4.0),
                      color: GUIcolor,
                    ),
                    width: 230,
                    height: 175,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        notification,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
               ]
              ),
              if (characteristic.uuid.toString().substring(4,8) == "2a19")
              SizedBox(
                height: 5,
              ),
              if (characteristic.uuid.toString().substring(4,8) == "2a19")
              Card(
                child: Container(
                  decoration: new BoxDecoration(
                    border: Border.all(color: Colors.lightGreen),
                    borderRadius: new BorderRadius.circular(4.0),
                    color: Colors.lightGreen,
                  ),
                  width: 392,
                  height: 75,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      funfact,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
              ,
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Card(
                      child: Container(
                        decoration: new BoxDecoration(
                          border: Border.all(color: (characteristic.uuid.toString().substring(4,8) == "2a19") ? GUIcolort :
                          (characteristic.uuid.toString().substring(4,8) == "2a20") ? GUIcolorh : GUIcolorl),
                          borderRadius: new BorderRadius.circular(4.0),
                          color: (characteristic.uuid.toString().substring(4,8) == "2a19") ? GUIcolort :
                          (characteristic.uuid.toString().substring(4,8) == "2a20") ? GUIcolorh : GUIcolorl,
                        ),
                        width: 125,
                        height: 152,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              child: GestureDetector(
                                onTap: onNotificationPressed, // Image tapped
                                child: (characteristic.uuid.toString().substring(4,8) == "2a19") ?
                              Image.asset(
                                'assets/temp.png',
                                height: 100,
                                fit: BoxFit.cover,
                              ) :
                              (characteristic.uuid.toString().substring(4,8) == "2a20") ?
                              Image.asset(
                                'assets/hum.png',
                                height: 100,
                                fit: BoxFit.cover,
                              ) :
                              Image.asset(
                                'assets/light.png',
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            ),
                            SizedBox(
                              height: 10,
                            ),

                            Text((floatList.length == 0) ? "-" :
                            (characteristic.uuid.toString().substring(4,8) == "2a19") ? "${floatList[0].toStringAsFixed(2)}" ' °C' :
                            (characteristic.uuid.toString().substring(4,8) == "2a20") ? "${floatList[0].toStringAsFixed(2)}" ' %' :
                            "${floatList[0].toStringAsFixed(2)}" ' lux',
                              style: TextStyle(fontSize: 17),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Container(
                      decoration: new BoxDecoration(
                        border: Border.all(color: (characteristic.uuid.toString().substring(4,8) == "2a19") ? GUIcolort :
                        (characteristic.uuid.toString().substring(4,8) == "2a20") ? GUIcolorh : GUIcolorl),
                        borderRadius: new BorderRadius.circular(4.0),
                        color: (characteristic.uuid.toString().substring(4,8) == "2a19") ? GUIcolort :
                        (characteristic.uuid.toString().substring(4,8) == "2a20") ? GUIcolorh : GUIcolorl,
                      ),
                      width: 259,
                      height: 152,
                        child: SfCartesianChart(title: ChartTitle(text: (characteristic.uuid.toString().substring(4,8) == "2a19") ? "Temperature" :
                        (characteristic.uuid.toString().substring(4,8) == "2a20") ? "Humidity" :
                        "Light",
                          textStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        )
                        ),plotAreaBorderColor: Colors.black,
                          primaryXAxis: NumericAxis(
                            labelFormat: '{value} s',
                            labelStyle: TextStyle(color: Colors.black),
                            majorGridLines: MajorGridLines(color: Colors.black),
                            axisLine: AxisLine(color: Colors.black),
                            interval: 1, maximumLabels: 5
                          ),

                          primaryYAxis: NumericAxis(
                              labelFormat: (characteristic.uuid.toString().substring(4,8) == "2a19") ? '{value} °C' :
                              (characteristic.uuid.toString().substring(4,8) == "2a20") ? '{value} %' :
                              '{value} lux',
                              labelStyle: TextStyle(color: Colors.black),
                              majorGridLines: MajorGridLines(color: Colors.black),
                              axisLine: AxisLine(color: Colors.black),

                          ),
                            series: <LineSeries<SalesData, double>>[
                              LineSeries<SalesData, double>(
                                // Bind data source
                                  dataSource:  [
                                    SalesData(count.ceil().toDouble()-9, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[0] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[0] :
                                    sflight[0], Colors.white),
                                    SalesData(count.ceil().toDouble()-8, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[1] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[1] :
                                    sflight[1], Colors.white),
                                    SalesData(count.ceil().toDouble()-7, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[2] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[2] :
                                    sflight[2], Colors.white),
                                    SalesData(count.ceil().toDouble()-6, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[3] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[3] :
                                    sflight[3], Colors.white),
                                    SalesData(count.ceil().toDouble()-5, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[4] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[4] :
                                    sflight[4], Colors.white),
                                    SalesData(count.ceil().toDouble()-4, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[5] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[5] :
                                    sflight[5], Colors.white),
                                    SalesData(count.ceil().toDouble()-3, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[6] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[6] :
                                    sflight[6], Colors.white),
                                    SalesData(count.ceil().toDouble()-2, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[7] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[7] :
                                    sflight[7], Colors.white),
                                    SalesData(count.ceil().toDouble()-1, (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[8] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[8] :
                                    sflight[8], Colors.white),
                                    SalesData(count.ceil().toDouble(), (characteristic.uuid.toString().substring(4,8) == "2a19") ? sftemp[9] :
                                    (characteristic.uuid.toString().substring(4,8) == "2a20") ? sfhum[9] :
                                    sflight[9], Colors.white),

                                  ],
                                  pointColorMapper:(SalesData sales, _) => sales.segmentColor,
                                  xValueMapper: (SalesData sales, _) => sales.year,
                                  yValueMapper: (SalesData sales, _) => sales.sales,
                                  animationDuration: 500
                              )
                            ]
                        )
                      )
                    ),

                  ],
                ),
              ),
            ],
          );

      },
    );
  }
}



class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subtitle1,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subtitle1?.color,
        ),
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales, this.segmentColor);
  final double year;
  final double sales;
  final Color segmentColor;
}