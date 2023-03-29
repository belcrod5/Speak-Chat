import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';


final Logger _logger = Logger('MyApp');


void main() async ***REMOVED***
  
  //環境変数を読み込む
  await dotenv.load(fileName: ".env");

  // スリープさせない
  KeepScreenOn.turnOn();
  
  //initializeDateFormatting();
  Intl.defaultLocale = 'ja_JP';

  //ロケール・言語設定（iOSはInfo.plistで直った）
  Intl.withLocale('ja', () => 

    runApp(const MyApp())
  );
***REMOVED***


class SettingView extends StatefulWidget ***REMOVED***

  const SettingView(***REMOVED***super.key***REMOVED***);

  @override
  State<SettingView> createState() => _SettingViewState();
***REMOVED***

class _SettingViewState extends State<SettingView> ***REMOVED***
  String _selectedItemMy = "error";
  String _selectedItemBot = "error";
  final List<String> _items = ["error"];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;

  @override
  void initState() ***REMOVED***
    super.initState();

    Future(() async ***REMOVED***

      prefs = await SharedPreferences.getInstance();

      List voices = await tts.getVoices;

      _items.clear();
      for(var item in voices)***REMOVED***
        var map = item as Map<Object?, Object?>;
        if(map["locale"].toString().toLowerCase().contains("ja"))***REMOVED***
          _logger.info(map["name"]);
          _items.add(map["name"].toString());
        ***REMOVED***
      ***REMOVED***
      if(_items.isNotEmpty)***REMOVED***
        
        _selectedItemMy = prefs.getString("voice_わたし") ?? _items[0];
        _selectedItemBot = prefs.getString("voice_ロボット") ?? _items[0];
      ***REMOVED***

      // プルダウンを反映
      setState(() ***REMOVED******REMOVED***);
      
    ***REMOVED***);
  ***REMOVED***

  Future<void> _changeVoice(String voiceName, String who, bool speak) async ***REMOVED***

    prefs.setString("voice_$who", voiceName);

    if(!speak)
    ***REMOVED***
      return;
    ***REMOVED***

    await tts.stop();
    await tts.setVoice(***REMOVED***
      'name': voiceName,
      'locale': 'ja-JP'
    ***REMOVED***);
    
    await tts.speak("$whoの声が設定されました");
  ***REMOVED***

  @override
  Widget build(BuildContext context) ***REMOVED***
    return Scaffold(
      appBar: AppBar(
          title: const Text("Setting"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('わたしの声'),
            DropdownButton<String>(
              value: _selectedItemMy,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) ***REMOVED***
                setState(() ***REMOVED***
                  _selectedItemMy = value!;
                  _changeVoice(_selectedItemMy, "わたし", true);
                ***REMOVED***);
              ***REMOVED***,
            ),
            const Divider(height: 100),

            const Text('ロボットの声'),
            DropdownButton<String>(
              value: _selectedItemBot,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) ***REMOVED***
                setState(() ***REMOVED***
                  _selectedItemBot = value!;
                  _changeVoice(_selectedItemBot, "ロボット", true);
                ***REMOVED***);
              ***REMOVED***,
            ),
          ]
        )
      ),
    );
  ***REMOVED***
***REMOVED***


class MyApp extends StatelessWidget ***REMOVED***
  const MyApp(***REMOVED***super.key***REMOVED***);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) ***REMOVED***
    return MaterialApp(
      title: 'Speak Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Speak Chat'),

      //ロケール・言語設定（iOSはInfo.plistで直った）
      localizationsDelegates: const [
        // localizations delegateを追加
        //AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      //ロケール・言語設定（iOSはInfo.plistで直った）
      supportedLocales: const [Locale('ja', 'JP')],
      locale: const Locale('ja', 'JP'),

    );
  ***REMOVED***
***REMOVED***


class MyHomePage extends StatefulWidget ***REMOVED***
  const MyHomePage(***REMOVED***super.key, required this.title***REMOVED***);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
***REMOVED***


class _MyHomePageState extends State<MyHomePage> ***REMOVED***
  String lastWords = '';
  
  List<Object> chatMessages = [];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;
  var inputTextcontroller = TextEditingController();
  ScrollController scrollController = ScrollController();


  @override
  void initState() ***REMOVED***
    super.initState();


    Future(() async ***REMOVED***

      prefs = await SharedPreferences.getInstance();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      

    ***REMOVED***);

    Future(() async ***REMOVED***
      // スピーカーから音を出すように設定
      await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ]);

      // 音声をキューに追加する(Androidのみ)
      if(Platform.isAndroid)***REMOVED***
        tts.setQueueMode(1);
      ***REMOVED***

      // 話す速度の設定
      await tts.setPitch(0.9);
      await tts.setSpeechRate(0.6);
    ***REMOVED***);

    // 設定画面を開く
    Future(() ***REMOVED***
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingView()),
      );
    ***REMOVED***);
  ***REMOVED***

  String _getVoiceName(String type)
  ***REMOVED***
    return (type == "user" ? prefs.getString("voice_わたし") : prefs.getString("voice_ロボット"))?? "";
  ***REMOVED***

  // 読み上げ
  Future<void> _speach(dynamic item) async ***REMOVED***

    
    // 停止して再生
    await tts.stop();
    await tts.setVoice(***REMOVED***
      'name': _getVoiceName(item["role"]),
      'locale': 'ja-JP'
    ***REMOVED***);
    
    await tts.speak(
      item["content"]
    );
  ***REMOVED***

  // 音声入力開始
  _speak()  ***REMOVED***


    Future(() async ***REMOVED***
      // 再生を停止し
      await tts.stop();
    ***REMOVED***);

    // 入力を空にする
    setState(() ***REMOVED***
      lastWords = "";
    ***REMOVED***);

    showDialog<String>(
      context: context,
      builder: (BuildContext context) ***REMOVED***
        
        return const SpeechDialog();
      ***REMOVED***,
    ).then((value) ***REMOVED***

      _logger.info("end dialog!");

      setState(() ***REMOVED***
        if(value != null)***REMOVED***
          lastWords = value;
        ***REMOVED***
      ***REMOVED***);


      
      _ai();



    ***REMOVED***);
  ***REMOVED***

    



  // メッセージを消去
  Future<void> _cleanMessage() async ***REMOVED***
    setState(() ***REMOVED***
      chatMessages.clear();
    ***REMOVED***);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('メッセージ削除しました'),
    ));
  ***REMOVED***
  

  // ChatGPT
  Future<void> _ai() async ***REMOVED***
    
    _logger.info("_ai");
    
    // 入力が何も無ければスキップ
    if(lastWords == "")
    ***REMOVED***
      return;
    ***REMOVED***

    // 下までスクロール
    scrollController.jumpTo(scrollController.position.maxScrollExtent);

    
    // 停止して再生
    await tts.stop();
    await tts.setVoice(***REMOVED***'name': _getVoiceName("user"), 'locale': 'ja-JP'***REMOVED***);
    await tts.speak(
      lastWords
    );
    


    // 送信するメッセージを追加
    chatMessages.add(***REMOVED***"role": "user", "content": lastWords***REMOVED***);

    setState(() ***REMOVED***
      
      inputTextcontroller.clear();

      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus) ***REMOVED***
        currentFocus.unfocus();
      ***REMOVED***
    ***REMOVED***);


    // 現在の日時を追加して複製
    List<Object> chatMessagesClone = [
      ***REMOVED***"role": "user", "content": DateFormat('今は yyyy年MM月dd日 HH時mm分です').format(DateTime.now())***REMOVED***,
      ...chatMessages
    ];


    Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
    Map<String, String> headers = ***REMOVED***
      'Content-type': 'application/json',
      "Authorization": "Bearer $***REMOVED***dotenv.get("OPEN_AI_API_KEY")***REMOVED***"
    ***REMOVED***;
    String body = json.encode(***REMOVED***
      "frequency_penalty": 0,
      "max_tokens": 512,
      "messages": chatMessagesClone,
      "model": "gpt-3.5-turbo",
      "presence_penalty": 0,
      "stream": true,
      "temperature": 0.7,
      "top_p": 1
    ***REMOVED***);


    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;
    request.followRedirects = false;

    final response = await request.send();


    if(response.statusCode != 200)
    ***REMOVED***
      setState(() ***REMOVED***

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("通信エラーが発生しました $***REMOVED***response.statusCode***REMOVED***"),
        ));
      ***REMOVED***);

      return;
    ***REMOVED***

    _logger.info(response.statusCode);
    


    // 受信メッセージを追加
    chatMessages.add(***REMOVED***"role": "assistant", "content": ""***REMOVED***);
    setState(() ***REMOVED***
      chatMessages = chatMessages;
    ***REMOVED***);

    var receiveMsg = "";
    var receiveMsgSpeak = "";
    var receiveDone = false;

    await for (final message in response.stream.transform(utf8.decoder)) ***REMOVED***

      message.split("\n").forEach((msg) ***REMOVED***

        if(!msg.startsWith("data: "))
        ***REMOVED***
          return;
        ***REMOVED***

        var jsonMsg = msg.replaceFirst(RegExp("^data: "), "");

        if(jsonMsg == "[DONE]")
        ***REMOVED***
          return;
        ***REMOVED***

        final data = json.decode(jsonMsg);
        

        var content = data["choices"][0]["delta"]["content"];
        if(content == null)***REMOVED***
          return;
        ***REMOVED***

        receiveMsg += content;

        receiveMsgSpeak += content;
        
        // まだ終わっていない時
        if(!receiveDone)
        ***REMOVED***
          // 少量のテキストで喋りださないように最小数チェック
          if(receiveMsgSpeak.length > 50)
          ***REMOVED***
            var stopIndex = receiveMsgSpeak.indexOf(RegExp("、|。|\n"), 50);
            if(stopIndex > 0)
            ***REMOVED***
              var speackMsg = receiveMsgSpeak.substring(0, stopIndex);
              receiveMsgSpeak = receiveMsgSpeak.substring(stopIndex+1, receiveMsgSpeak.length);

              () async ***REMOVED***
                // 受信メッセージを話す
                await tts.setVoice(***REMOVED***'name': _getVoiceName("robot"), 'locale': 'ja-JP'***REMOVED***);
                await tts.speak(
                  speackMsg
                );
              ***REMOVED***();
            ***REMOVED***
          ***REMOVED***
        ***REMOVED***

        // 最後に追加したデータにテキストを設定する
        dynamic item = chatMessages[chatMessages.length-1];
        item["content"] = receiveMsg;
        chatMessages[chatMessages.length-1] = item;
        
        setState(() ***REMOVED***
          chatMessages = chatMessages;

          // 下までスクロール
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        ***REMOVED***);

      ***REMOVED***);
      
    ***REMOVED***

    receiveDone = true;

    // 下までスクロール
    scrollController.jumpTo(scrollController.position.maxScrollExtent);

    // 残りの受信メッセージを話す
    await tts.setVoice(***REMOVED***'name': _getVoiceName("robot"), 'locale': 'ja-JP'***REMOVED***);
    await tts.speak(
      receiveMsgSpeak
    );



  ***REMOVED***


  // テキスト入力変更
  void _handleText(String e) ***REMOVED***
    setState(() ***REMOVED***
      lastWords = e;
    ***REMOVED***);
  ***REMOVED***
  

  @override
  Widget build(BuildContext context) ***REMOVED***
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () ***REMOVED***
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingView()),
                );
              ***REMOVED***,
            ),
          ],
      ),
      body: Column(
          
        children: <Widget>[
          
          Expanded(
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(

                controller: scrollController,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: chatMessages.map((dynamic item)=>(
                    GestureDetector(
                      onTap: () ***REMOVED***
                          _speach(item);
                      ***REMOVED***,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(
                              item["role"] == "user" ? "わたし　：" : "ロボット：",
                              style: TextStyle(
                                color: item["role"] == "user" ? Colors.blue : Colors.green, // テキストの色を青に設定
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item["content"],
                                softWrap: true,
                              )
                            )
                          ]
                        )
                      )
                    )
                  )).toList()
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:Row(
            
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                    child:
                      IconButton(
                        onPressed: _cleanMessage,
                        icon: const Icon(Icons.cleaning_services),
                        iconSize: 18,
                        color:const Color.fromARGB(255, 255, 255, 255),
                      ),
                  ),
                ),
                Expanded(
                  child: 
                    TextFormField(
                      controller: inputTextcontroller,
                      enabled: true,
                      obscureText: false,
                      maxLines: null,
                      onChanged: _handleText,
                      decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: _speak,
                        icon: const Icon(Icons.mic),
                      ),
                    ),
                    )
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                  child:
                    IconButton(
                      onPressed: _ai,
                      icon: const Icon(Icons.send),
                      iconSize: 18,
                      color:const Color.fromARGB(255, 255, 255, 255),
                    ),
                )
              ],
            )
          )
        ],
      ),
    );
  ***REMOVED***
***REMOVED***


class SpeechDialog extends StatefulWidget ***REMOVED***
  
  const SpeechDialog(***REMOVED***Key? key***REMOVED***) : super(key: key);

  @override
  SpeechDialogState createState() => SpeechDialogState();
***REMOVED***

class SpeechDialogState extends State<SpeechDialog> ***REMOVED***
  String lastStatus = "";
  String lastError = "";
  String lastWords = "";
  stt.SpeechToText speech = stt.SpeechToText();
  ScrollController scrollController = ScrollController();
  double soundLevel = 0;
  



  @override
  void initState() ***REMOVED***
    super.initState();

    
    Future(() async ***REMOVED***
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
    ***REMOVED***);

    Future(() async ***REMOVED***

      // スピーチを初期化
      bool available = await speech.initialize(
        onError: (SpeechRecognitionError error) ***REMOVED***
          if(!mounted) ***REMOVED*** return; ***REMOVED***
          setState(() ***REMOVED***
            lastError = '$***REMOVED***error.errorMsg***REMOVED*** - $***REMOVED***error.permanent***REMOVED***';
          ***REMOVED***);
        ***REMOVED***,
        onStatus: (String status) ***REMOVED***
          if(!mounted) ***REMOVED*** return; ***REMOVED***
          setState(() ***REMOVED***
            lastStatus = status;
            _logger.info(status);

            // 下までスクロール
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          ***REMOVED***);
        ***REMOVED***
      );

      if (available) ***REMOVED***
        
        
        speech.listen(onResult: (SpeechRecognitionResult result) ***REMOVED***
          if(!mounted) ***REMOVED*** return; ***REMOVED***
          
          setState(() ***REMOVED***
            lastWords = result.recognizedWords;
            
          ***REMOVED***);
        ***REMOVED***,
        onSoundLevelChange:(level)***REMOVED***

          if(!mounted) ***REMOVED*** return; ***REMOVED***

          setState(() ***REMOVED***
            if(lastStatus != "listening")
            ***REMOVED***
              // TODO:iOSの時には録音準備完了の音が鳴らないので鳴らしたいがspeech.listen状態では鳴らないようです(バイブレーションも駄目)
            ***REMOVED***
            lastStatus = "listening";
            soundLevel = level * -1 ;
          ***REMOVED***);
        ***REMOVED***,
        localeId: "ja-JP"
        );
      ***REMOVED*** else ***REMOVED***
        _logger.info("The user has denied the use of speech recognition.");
      ***REMOVED***
      
    ***REMOVED***);
  ***REMOVED***


  @override
  Widget build(BuildContext context) ***REMOVED***
    return AlertDialog(

      title: Center(child:Text(lastStatus == "done" ? "終了" : lastStatus == "listening" ? "聞き取り中" : "準備中 $lastStatus")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Text(lastWords, style:const TextStyle(
                                color: Colors.cyan
                              ),),
            ),
          ),
          CircleAvatar(
            radius: 20 + soundLevel,
            backgroundColor: lastStatus == "listening" ? const Color.fromARGB(255, 0, 149, 255) : const Color.fromARGB(255, 128, 128, 128),
            child:
              IconButton(
                onPressed: ()***REMOVED***

                  Navigator.of(context).pop(lastWords);
                ***REMOVED***,
                icon: const Icon(Icons.mic),
                iconSize: 18 + soundLevel,
                color:const Color.fromARGB(255, 255, 255, 255),
              ),
          ),
        ],
      ),
    );
  ***REMOVED***

  @override
  void dispose() ***REMOVED***

    // 必要なクリーンアップ処理を実行
    super.dispose();

    speech.stop();
    
  ***REMOVED***
***REMOVED***