// https://stackoverflow.com/questions/65523645/how-to-handle-complex-api-data-response-in-flutter-getx-using-observable-method
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:convert';

const String _serverUrl =
    'http://192.168.0.108:51212/offline_train?batch_size=1024&n_updates=500&name_of_trained_model=test3';
const String _dblistUrl = 'http://192.168.0.108:51212/check_offlinedataset';
const String _agentlistUrl = 'http://192.168.0.108:51212/check_agent_list';

final pagecontroller = Get.put(pageController());
final obj = Get.put(learningController());

class learningController extends GetxController {
  var _result = [].obs;
  var _dbresult = [].obs;
  var _agentresult = [].obs;

  var _maindataAvailable = false.obs;
  var _dbdataAvailable = false.obs;
  var _agentdataAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('start');
    // fetchTransactions();
  }

  RxBool get maindataAvailable => _maindataAvailable;
  RxBool get dbdataAvailable => _dbdataAvailable;
  RxBool get agentdataAvailable => _agentdataAvailable;

  RxList get result => _result;
  RxList get dbresult => _dbresult;
  RxList get agentresult => _agentresult;

  mainpagedata() async {
    _maindataAvailable.value = false;
    await http
        // yield http
        // http
        .get(Uri.parse(_serverUrl),
            headers: {"Access-Control_Allow_Origin": "*"})
        .then((response) {
          response.statusCode == 200 ? _result.add(response.body) : null;
        })
        .catchError((err) => print(err))
        .whenComplete(() {
          _maindataAvailable.value = true;
          print("complete");
        });
    throw "";
  }

  getdblist() async {
    _dbdataAvailable.value = false;
    _dbresult.value = [];
    await http
        // yield http
        // http
        .get(Uri.parse(_dblistUrl),
            headers: {"Access-Control_Allow_Origin": "*"})
        .then((response) {
          response.statusCode == 200 ? _dbresult.add(response.body) : null;
        })
        .catchError((err) => print(err))
        .whenComplete(() {
          _dbdataAvailable.value = true;
        });
    throw "";
  }

  getagentlist() async {
    _agentdataAvailable.value = false;
    _agentresult.value = [];
    await http
        // yield http
        // http
        .get(Uri.parse(_agentlistUrl),
            headers: {"Access-Control_Allow_Origin": "*"})
        .then((response) {
          response.statusCode == 200 ? _agentresult.add(response.body) : null;
        })
        .catchError((err) => print(err))
        .whenComplete(() {
          _agentdataAvailable.value = true;
        });
    throw "";
  }
}

class pageController extends GetxController {
  var pageindex = 0.obs;

  controllmainpages() {
    if (pageindex.value == 0) {
      return mainplace();
    } else if (pageindex.value == 1) {
      return dbpage();
    } else {
      return agentpage();
    }
  }
}

class agentpage extends StatelessWidget {
  const agentpage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // child: Obx((() => Text(obj.dbresult.toString())))
        child: Obx(() => obj.agentdataAvailable.value
            ? ListView(
                // children: Text(jsonDecode(obj.dbresult[0])['0'].toString())
                children: List<Widget>.generate(
                    jsonDecode(obj.agentresult[0]).length, (index) {
                return ListTile(
                  title:
                      Text(jsonDecode(obj.agentresult[0])["$index"].toString()),
                );
              }).toList())
            : Text("weighting...")));
  }
}

class dbpage extends StatelessWidget {
  const dbpage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        // child: Obx((() => Text(obj.dbresult.toString())))
        child: Obx(() => obj.dbdataAvailable.value
            ? ListView(
                // children: Text(jsonDecode(obj.dbresult[0])['0'].toString())
                children: List<Widget>.generate(
                    jsonDecode(obj.dbresult[0]).length, (index) {
                return ListTile(
                  title: Text(jsonDecode(obj.dbresult[0])["$index"].toString()),
                );
              }).toList())
            : Text("weighting...")));
  }
}

class mainplace extends StatelessWidget {
  const mainplace({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 34, 145, 67),
      child: Obx(() => obj._maindataAvailable.value
          ? Text(jsonDecode(obj.result[0]).toString())
          : Text("weighting")),
    );
  }
}

void main() async {
  runApp(GetMaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EHRNC HVAC system controller",
            style: TextStyle(
              color: Color.fromARGB(255, 48, 46, 46),
              letterSpacing: 2.0,
              fontSize: 20.0,
            )),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Flexible(
            child: Container(
              color: Color.fromARGB(255, 255, 255, 255),
              child: Row(
                children: [
                  Flexible(
                    child: sidebar(),
                    flex: 1,
                  ),
                  Flexible(
                    child: Obx(() => pagecontroller.controllmainpages()),
                    flex: 7,
                  ),
                ],
              ),
            ),
            flex: 8,
          )
        ],
      ),
    );
  }
}

class sidebar extends StatelessWidget {
  const sidebar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 246, 248, 248),
      child: Column(
        children: [
          Flexible(
            child: Container(
              // color: Color.fromARGB(255, 240, 243, 239),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.motorcycle),
                          onPressed: () {
                            pagecontroller.pageindex.value = 0;
                            obj.mainpagedata();
                          },
                        ),
                        Text("MAIN")
                      ],
                    ),
                    flex: 1,
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.access_time_sharp),
                          onPressed: () {
                            pagecontroller.pageindex.value = 1;
                            obj.getdblist();
                          },
                        ),
                        Text("DB")
                      ],
                    ),
                    flex: 1,
                  ),
                  Flexible(
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.battery_alert),
                          onPressed: () {
                            pagecontroller.pageindex.value = 2;
                            obj.getagentlist();
                          },
                        ),
                        // Text("agent"),/
                        Text("AGENT"),
                      ],
                    ),
                    flex: 1,
                  )
                ],
              ),
            ),
            flex: 1,
          ),
          Flexible(
            child: Container(
                // color: Color.fromARGB(255, 228, 21, 21),
                ),
            flex: 2,
          )
        ],
      ),
    );
  }
}
