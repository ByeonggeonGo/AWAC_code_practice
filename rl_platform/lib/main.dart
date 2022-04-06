// https://stackoverflow.com/questions/65523645/how-to-handle-complex-api-data-response-in-flutter-getx-using-observable-method
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:convert';

const String _dblistUrl = 'http://192.168.0.108:51212/check_offlinedataset';
const String _agentlistUrl = 'http://192.168.0.108:51212/check_agent_list';

final pagecontroller = Get.put(pageController());
final obj = Get.put(learningController());
var main_bottom_index = 0.obs;

var batch_size_list = [512, 1024, 2048].map((i) {
  return (DropdownMenuItem(
    child: Text(i.toString()),
    value: i.toString(),
  ));
}).toList();

var update_num_list = [500, 1000, 2000, 4000, 8000].map((i) {
  return (DropdownMenuItem(
    child: Text(i.toString()),
    value: i.toString(),
  ));
}).toList();

class learningController extends GetxController {
  var _result = [].obs;
  var _dbresult = [].obs;
  var _agentresult = [].obs;

  var _maindataAvailable = false.obs;
  var _dbdataAvailable = false.obs;
  var _agentdataAvailable = false.obs;

  var batch_sz = '1024'.obs;
  var offline_learn_size = '500'.obs;
  var offline_learn_agent_name = 'agent'.obs;
  var offline_learn_status = false.obs;
  // String offline_learn_url =
  //     "http://192.168.0.108:51212/offline_train?batch_size=${batch_sz.value}&n_updates=${offline_learn_size.value}&name_of_trained_model=${offline_learn_agent_name.value}";

  var batch_sz_online = '1024'.obs;
  var online_learn_size = '500'.obs;
  var online_learn_target_agent_name = ''.obs;
  var online_learn_after_agent_name = ''.obs;
  var dataset_name = ''.obs;
  var after_dataset_name = ''.obs;
  var online_learn_status = false.obs;

  var learning_progress_num = 0.obs;

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

  offline_learning() async {
    offline_learn_status.value = false;
    String offlineLearnUrl =
        "http://192.168.0.108:51212/offline_train?batch_size=${batch_sz.value}&n_updates=${offline_learn_size.value}&name_of_trained_model=${offline_learn_agent_name.value}";

    // var request =  await http
    //     // yield http
    //     // http
    //     .get(Uri.parse(offlineLearnUrl),
    //         headers: {"Access-Control_Allow_Origin": "*"})
    //     .then((response) {
    //       response.statusCode == 200 ? null : null;
    //     })
    //     .catchError((err) => print(err))
    //     .whenComplete(() {
    //       offline_learn_status.value = true;
    //       print("complete");
    //     });

    var request = http.Request(
      'GET',
      Uri.parse(offlineLearnUrl),
    );
    var streamedResponse = await request.send();
    // var response = await http.Response.fromStream(streamedResponse);
    // await for (var value in streamedResponse) {
    //   print(value);
    // }
    // var responseString = await streamedResponse.stream.bytesToString();
    // var responseString = streamedResponse.stream.listen(null).onData((data) {
    //   print(data);
    // });
    var dat = [];
    var responseString = streamedResponse.stream.listen((Value) {
      dat.add(Value);
      print(dat.length);
    });

    // print(responseString);
    // streamedResponse.stream.listen((var newBytes) {
    //   // print(newBytes.toString());
    // });
  }

  online_learning() async {
    online_learn_status.value = false;
    String onlineLearnUrl =
        "http://192.168.0.108:51212/online_train?batch_size=${batch_sz_online.value}&num_runs=${online_learn_size.value}&name_of_target_model=${online_learn_target_agent_name.value}&name_of_updated_model=${online_learn_after_agent_name.value}&name_of_memory=${dataset_name.value}&name_of_updated_memory=${after_dataset_name.value}";

    await http
        .get(Uri.parse(onlineLearnUrl),
            headers: {"Access-Control_Allow_Origin": "*"})
        .then((response) {
          response.statusCode == 200 ? null : null;
        })
        .catchError((err) => print(err))
        .whenComplete(() {
          online_learn_status.value = true;
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
      color: Color.fromARGB(255, 228, 228, 228),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            fit: FlexFit.tight,
            flex: 2,
            child: Container(
              padding: EdgeInsets.fromLTRB(2, 8, 0, 0),
              child: Text(
                "Controller Management system",
                style: TextStyle(
                  color: Color.fromARGB(255, 75, 116, 93),
                  letterSpacing: 2.0,
                  fontSize: 16.0,
                ),
              ),
              color: Color.fromARGB(255, 231, 231, 230),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Column(
                    children: [
                      Flexible(
                        flex: 4,
                        fit: FlexFit.tight,
                        child: Container(
                          // color: Colors.black,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 255, 255, 255),
                              shape: BoxShape.circle),
                          child: IconButton(
                            onPressed: (() => main_bottom_index.value = 0),
                            icon: Icon(Icons.access_alarms_sharp),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: Text("Offline learning"),
                      )
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Column(
                    children: [
                      Flexible(
                        flex: 4,
                        fit: FlexFit.tight,
                        child: Container(
                          // color: Colors.black,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 255, 255, 255),
                              shape: BoxShape.circle),
                          child: IconButton(
                            onPressed: (() => main_bottom_index.value = 1),
                            icon: Icon(Icons.access_alarms_sharp),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: Text("Online learning"),
                      )
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Column(
                    children: [
                      Flexible(
                        flex: 4,
                        fit: FlexFit.tight,
                        child: Container(
                          // color: Colors.black,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 255, 255, 255),
                              shape: BoxShape.circle),
                          child: IconButton(
                            onPressed: (() => main_bottom_index.value = 2),
                            icon: Icon(Icons.access_alarms_sharp),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: Text("Model hosting"),
                      )
                    ],
                  ),
                ),
              ],
            ),
            flex: 4,
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Obx(() => main_bottom_index.value == 0
                ? OfflinelearnPage()
                : main_bottom_index.value == 1
                    ? OnlinelearningPage()
                    : SizedBox()),
            flex: 25,
          ),
        ],
      ),
    );
  }
}

class OnlinelearningPage extends StatelessWidget {
  const OnlinelearningPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: 4,
          child: Container(
            height: 400,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter batch size'),
                    onSubmitted: (value) {
                      obj.batch_sz_online.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter num run'),
                    onSubmitted: (value) {
                      obj.online_learn_size.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter name of target model'),
                    onSubmitted: (value) {
                      obj.online_learn_target_agent_name.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter name of target model after train'),
                    onSubmitted: (value) {
                      obj.online_learn_after_agent_name.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select dataset'),
                    onSubmitted: (value) {
                      obj.dataset_name.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter dataset name after online train'),
                    onSubmitted: (value) {
                      obj.after_dataset_name.value = value;
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      obj.online_learning();
                    },
                    child: Text("Click to update agent"),
                  )
                ],
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Learning Progress'),
                Obx(() => obj.online_learn_status.value
                    ? Text("...learning complete...")
                    : Text('..gogogo..'))
              ],
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Performance summary'),
              ],
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
          ),
        ),
      ],
    );
  }
}

class OfflinelearnPage extends StatelessWidget {
  const OfflinelearnPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          fit: FlexFit.tight,
          flex: 4,
          child: Container(
            height: 300,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter batch size'),
                    onSubmitted: (value) {
                      obj.batch_sz.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter iter number'),
                    onSubmitted: (value) {
                      obj.offline_learn_size.value = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your model name for saved'),
                    onSubmitted: (String value) {
                      obj.offline_learn_agent_name.value = value;
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      obj.offline_learning();
                    },
                    child: Text("Click to train agent"),
                  )
                ],
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Learning Progress'),
                Obx(() => obj.offline_learn_status.value
                    ? Text("...learning complete...")
                    : Text('.........'))
              ],
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
          ),
        ),
        Flexible(
          fit: FlexFit.tight,
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Performance summary'),
              ],
            ),
            // color: Color.fromARGB(255, 240, 218, 216),
          ),
        ),
      ],
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
      body: Container(
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
                            // obj.mainpagedata();
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
