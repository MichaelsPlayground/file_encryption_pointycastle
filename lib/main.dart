import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'File encryption pointycastle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    descriptionController.text = txtDescription;
    _handleRadioValueChange1(0);
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController sourceFileController = TextEditingController();
  TextEditingController destinationFileController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  String txtDescription = 'AES-256 GCM file encryption, the key is'
      ' derivated by PBKDF2 from a user password.';
  bool encryptionMode = true; // true = encryption
  String runButtonText = 'encrypt';
  int _radioValue1 = -1;

  void _handleRadioValueChange1(int value) {
    setState(() {
      _radioValue1 = value;
      switch (_radioValue1) {
        case 0:
          encryptionMode = true;
          runButtonText = 'encrypt';
          _clearController();
          break;
        case 1:
          encryptionMode = false;
          runButtonText = 'decrypt';
          _clearController();
          break;
      }
    });
  }

  void _clearController() {
    sourceFileController.text = '';
    destinationFileController.text = '';
    passwordController.text = '';
    messageController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //SizedBox(height: 20),
                // form description
                TextFormField(
                  controller: descriptionController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enabled: false,
                  // false = disabled, true = enabled
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 20),
                new Text(
                  'Select encryption or decryption:',
                  style: new TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                // choose for encryption or decryption
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Radio(
                      value: 0,
                      groupValue: _radioValue1,
                      onChanged: (int? value) {
                        _handleRadioValueChange1(value!);
                      },
                      //onChanged: _handleRadioValueChange1,
                    ),
                    new Text(
                      'Encryption',
                      style: new TextStyle(fontSize: 16.0),
                    ),
                    new Radio(
                      value: 1,
                      groupValue: _radioValue1,
                      onChanged: (int? value) {
                        _handleRadioValueChange1(value!);
                      },
                      //onChanged: _handleRadioValueChange1,
                    ),
                    new Text(
                      'Decryption',
                      style: new TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // source file
                TextFormField(
                  controller: sourceFileController,
                  readOnly: true,
                  //enabled: false, // no direct access
                  maxLines: 3,
                  maxLength: 300,
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'source file',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please choose a file';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.grey,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {
                          //      plaintextController.text = '';
                        },
                        child: Text('Feld löschen'),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          Directory directory =
                          await getApplicationDocumentsDirectory();
                          final String sourceFilePath =
                              '${directory.path}/source.txt';

                          // here: for encryptio as well
                          final String cipherFilePath =
                              '${directory.path}/cipher.txt';

                          // here for decryption
                          final String decryptFilePath = '${directory
                              .path}/decrypt.txt';

                          if (encryptionMode) {
                            // encryption
                            sourceFileController.text = sourceFilePath;
                            destinationFileController.text = cipherFilePath;

                            // for test purposes we generate a test file
                            if (_fileExistsSync(sourceFilePath)) {
                              _deleteFileSync(sourceFilePath);
                            }
                            // generate a 'large' file with random content
                            final int testDataLength = (1024 * 9 - 2); // 1 mb
                            //final int testDataLength = (1024 * 7 + 0);
                            final step1 = Stopwatch()
                              ..start();
                            Uint8List randomData =
                            _generateRandomByte(testDataLength);
                            _generateLargeFileSync(
                                sourceFilePath, randomData, 1);
                            //_generateLargeFileSync(sourceFilePath, randomData, 50);
                          } else {
                            // decryption
                            sourceFileController.text = cipherFilePath;
                            destinationFileController.text = decryptFilePath;
                          }
                        },
                        child: Text('choose a file'),
                      ),
                    ),
                  ],
                ),

                // password
                SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  enabled: true,
                  // false = disabled, true = enabled
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'password',
                    hintText: 'please enter a password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please enter a password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.grey,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {
                          passwordController.text = '';
                        },
                        child: Text('clear field'),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () async {},
                        child: Text('aus Zwischenablage einfügen'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.grey,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {
                          _formKey.currentState!.reset();
                          //messageController.text = '';
                        },
                        child: Text('Formulardaten löschen'),
                      ),
                    ),
                    SizedBox(width: 25),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // are we running the encryption or decryption ?
                            if (encryptionMode) {
                              // true = encryption
                              String sourceFilePath = sourceFileController.text;
                              String destinationFilePath =
                                  destinationFileController.text;
                              String password = passwordController.text;
                              // check if source file exists, if false: return
                              if (!_fileExistsSync(sourceFilePath)) {
                                messageController.text =
                                'source file does not exist, aborted';
                                return;
                              } else {
                                int fileLength =
                                await _getFileLength(sourceFilePath);
                                messageController.text = 'source file is ' +
                                    fileLength.toString() +
                                    ' bytes long';
                              }
                              // check if destination file exists, if true: delete it
                              if (_fileExistsSync(destinationFilePath)) {
                                _deleteFileSync(destinationFilePath);
                                String message = messageController.text;
                                message =
                                    'destination file deleted\n' + message;
                                messageController.text = message;
                              }
                              // encrypt
                              try {
                                await _encryptAesGcmRandomNoncePbkdf2(
                                    sourceFilePath,
                                    destinationFilePath,
                                    password)
                                    .then((value) {})
                                    .catchError( (err) {
                                  messageController.text = '*** Error on encryption ***';
                                  return;
                                });
                              } catch (error) {
                                messageController.text = '*** Error on encryption ***';
                                return;
                              }
                              /*
                              await _encryptAesGcmRandomNoncePbkdf2(
                                  sourceFilePath,
                                  destinationFilePath,
                                  password);

                               */
                              // check if destination file exists, if true: give a message
                              if (_fileExistsSync(destinationFilePath)) {
                                int fileLength =
                                await _getFileLength(destinationFilePath);
                                String message = messageController.text;
                                message = 'destination file is ' +
                                    fileLength.toString() +
                                    ' bytes long\n' +
                                    message;
                                messageController.text = message;
                                return;
                              } else {
                                String message = messageController.text;
                                message =
                                    '*** ERROR on encryption ***\n' + message;
                                messageController.text = message;
                                return;
                              }
                              // end of encryption
                            } else {
                              // start of decryption
                              String sourceFilePath = sourceFileController.text;
                              String destinationFilePath =
                                  destinationFileController.text;
                              String password = passwordController.text;
                              // check if source file exists, if false: return
                              if (!_fileExistsSync(sourceFilePath)) {
                                messageController.text =
                                'source file does not exist, aborted';
                                return;
                              } else {
                                int fileLength =
                                await _getFileLength(sourceFilePath);
                                messageController.text = 'source file is ' +
                                    fileLength.toString() +
                                    ' bytes long';
                              }
                              // check if destination file exists, if true: delete it
                              if (_fileExistsSync(destinationFilePath)) {
                                _deleteFileSync(destinationFilePath);
                                String message = messageController.text;
                                message =
                                    'destination file deleted\n' + message;
                                messageController.text = message;
                              }
                              // decrypt
                              try {
                                await _decryptAesGcmRandomNoncePbkdf2(
                                    sourceFilePath,
                                    destinationFilePath,
                                    password)
                                    .then((value) {})
                                    .catchError( (err) {
                                  messageController.text = '*** Error on decryption ***';
                                  return;
                                });
                              } catch (error) {
                                messageController.text = '*** Error on decryption ***';
                                return;
                              }
                              /* with error dialog
                              try {
                                await _decryptAesGcmRandomNoncePbkdf2(
                                    sourceFilePath,
                                    destinationFilePath,
                                    password)
                                    .then((value) {})
                                    .catchError( (err) {
                                  _showErrorDialog(err.toString());
                                }); // Intentinally invalid credentials
                              } catch (error) {
                                _showErrorDialog(error.toString());
                              }*/
                              /*
                                await _decryptAesGcmRandomNoncePbkdf2(
                                    sourceFilePath,
                                    destinationFilePath,
                                    password);
*/
                              // check if destination file exists, if true: give a message
                              if (_fileExistsSync(destinationFilePath)) {
                                int fileLength =
                                await _getFileLength(destinationFilePath);
                                String message = messageController.text;
                                message = 'destination file is ' +
                                    fileLength.toString() +
                                    ' bytes long\n' +
                                    message;
                                messageController.text = message;
                              } else {
                                String message = messageController.text;
                                message =
                                    '*** ERROR on decryption ***\n' + message;
                                messageController.text = message;
                              }
                              // end of decryption
                            }
                          } else {
                            print("the form is no longer valid");
                          }
                        },
                        child: Text(runButtonText),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: messageController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  readOnly: false,
                  // false = disabled, true = enabled
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'messages',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: destinationFileController,
                  readOnly: true,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'destination file',
                    hintText: 'destination file',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.grey,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () {},
                        child: Text('Feld löschen'),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.blue,
                            textStyle: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Daten in die Zwischenablage kopiert'),
                            ),
                          );
                        },
                        child: Text('choose a file'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // using random access file, nonce is stored in the destination file
  _encryptAesGcmRandomNoncePbkdf2(String sourceFilePath,
      String destinationFilePath, String password) async {
    try {
      final int bufferLength = 2048;
      final int saltLength = 32; // salt for pbkdf2
      final int PBKDF2_ITERATIONS = 15000;
      final int nonceLength = 12; // nonce length
      File fileSourceRaf = File(sourceFilePath);
      File fileDestRaf = File(destinationFilePath);
      RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
      RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
      var fileRLength = await rafR.length();
      print('bufferLength: ' +
          bufferLength.toString() +
          ' fileRLength: ' +
          fileRLength.toString());
      await rafR.setPosition(0); // from position 0
      int fullRounds = fileRLength ~/ bufferLength;
      int remainderLastRound = (fileRLength % bufferLength) as int;
      print('fullRounds: ' +
          fullRounds.toString() +
          ' remainderLastRound: ' +
          remainderLastRound.toString());
      // derive key from password
      var passphrase = createUint8ListFromString(password);
      final salt = _generateRandomByte(saltLength);
      // generate and store salt in destination file
      await rafW.writeFrom(salt);
      pc.KeyDerivator derivator =
      new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
      pc.Pbkdf2Parameters params =
      new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
      derivator.init(params);
      final key = derivator.process(passphrase);
      // generate and store nonce in destination file
      final Uint8List nonce = _generateRandomByte(nonceLength);
      await rafW.writeFrom(nonce);
      // pointycastle cipher setup
      final cipher = pc.GCMBlockCipher(pc.AESEngine());
      var aeadParameters =
      pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
      cipher.init(true, aeadParameters); // true = encryption
      // now we are running the full rounds
      for (int rounds = 0; rounds < fullRounds; rounds++) {
        Uint8List bytesLoad = await rafR.read(bufferLength);
        Uint8List bytesLoadEncrypted = _processBlocks(cipher, bytesLoad);
        await rafW.writeFrom(bytesLoadEncrypted);
      }
      // last round
      if (remainderLastRound > 0) {
        Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
        Uint8List bytesLoadEncrypted = cipher.process(bytesLoadLast);
        await rafW.writeFrom(bytesLoadEncrypted);
      } else {
        Uint8List bytesLoadEncrypted =
        new Uint8List(16); // append one block with padding
        //int lastRoundEncryptLength = paddingCipher.doFinal(Uint8List(0), 0, bytesLoadEncrypted, 0);
        int lastRoundEncryptLength = cipher.doFinal(bytesLoadEncrypted, 0);
        await rafW.writeFrom(bytesLoadEncrypted);
      }
      // close all files
      await rafW.flush();
      await rafW.close();
      await rafR.close();
    } on Error {
      print('error');
    }
  }

// using random access file, nonce is stored in sourceFilePath
  _decryptAesGcmRandomNoncePbkdf2(String sourceFilePath,
      String destinationFilePath, String password) async {
    try {
      final int bufferLength = 2048;
      final int saltLength = 32; // salt for pbkdf2
      final int PBKDF2_ITERATIONS = 15000;
      final int nonceLength = 12; // nonce length
      File fileSourceRaf = File(sourceFilePath);
      File fileDestRaf = File(destinationFilePath);
      RandomAccessFile rafR = await fileSourceRaf.open(mode: FileMode.read);
      RandomAccessFile rafW = await fileDestRaf.open(mode: FileMode.write);
      var fileRLength = await rafR.length();
      print('bufferLength: ' +
          bufferLength.toString() +
          ' fileRLength: ' +
          fileRLength.toString());
      await rafR.setPosition(0); // from position 0
      int fullRounds = fileRLength ~/ bufferLength;
      int remainderLastRound = (fileRLength % bufferLength) as int;
      print('fullRounds: ' +
          fullRounds.toString() +
          ' remainderLastRound: ' +
          remainderLastRound.toString());
      // derive key from password
      // load salt from file
      final Uint8List salt = await rafR.read(saltLength);
      // load nonce from file
      final Uint8List nonce = await rafR.read(nonceLength);
      var passphrase = createUint8ListFromString(password);
      pc.KeyDerivator derivator =
      new pc.PBKDF2KeyDerivator(new pc.HMac(new pc.SHA256Digest(), 64));
      pc.Pbkdf2Parameters params =
      new pc.Pbkdf2Parameters(salt, PBKDF2_ITERATIONS, 32);
      derivator.init(params);
      final key = derivator.process(passphrase);
      // pointycastle cipher setup
      final cipher = pc.GCMBlockCipher(pc.AESEngine());
      var aeadParameters =
      pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
      cipher.init(false, aeadParameters); // false = decryption
      // now we are running the full rounds
      // correct number of full rounds if remaininderLastRound == 0
      if (remainderLastRound == 0) {
        fullRounds = fullRounds - 1;
        remainderLastRound = bufferLength;
      }
      for (int rounds = 0; rounds < fullRounds; rounds++) {
        Uint8List bytesLoad = await rafR.read(bufferLength);
        Uint8List bytesLoadDecrypted = _processBlocks(cipher, bytesLoad);
        await rafW.writeFrom(bytesLoadDecrypted);
      }
      // last round
      if (remainderLastRound > 0) {
        Uint8List bytesLoadLast = await rafR.read(remainderLastRound);
        Uint8List bytesLoadDecrypted = cipher.process(bytesLoadLast);
        await rafW.writeFrom(bytesLoadDecrypted);
      } else {
        /*
      do nothing
    */
      }
      // close all files
      await rafW.flush();
      await rafW.close();
      await rafR.close();
    } on Error {
      print('error');
    }
  }

  Uint8List _processBlocks(pc.BlockCipher cipher, Uint8List inp) {
    var out = new Uint8List(inp.lengthInBytes);
    for (var offset = 0; offset < inp.lengthInBytes;) {
      var len = cipher.processBlock(inp, offset, out, offset);
      offset += len;
    }
    return out;
  }

  Uint8List _generateRandomByte(int length) {
    final _sGen = Random.secure();
    final _seed =
    Uint8List.fromList(List.generate(32, (n) => _sGen.nextInt(255)));
    pc.SecureRandom sec = pc.SecureRandom("Fortuna")
      ..seed(pc.KeyParameter(_seed));
    return sec.nextBytes(length);
  }

  Future<int> _getFileLength(String path) async {
    File file = File(path);
    RandomAccessFile raf = await file.open(mode: FileMode.read);
    int fileLength = await raf.length();
    raf.close();
    return fileLength;
  }

  _deleteFileSync(String path) {
    File file = File(path);
    file.deleteSync();
  }

  Uint8List createUint8ListFromString(String s) {
    var ret = new Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }

  bool _fileExistsSync(String path) {
    File file = File(path);
    return file.existsSync();
  }

// reading from a file
  Uint8List _readUint8ListSync(String path) {
    File file = File(path);
    return file.readAsBytesSync();
  }

// writing to a file
  _writeUint8ListSync(String path, Uint8List data) {
    File file = File(path);
    file.writeAsBytesSync(data);
  }

// writing to a file
  _writeUint8List(String path, Uint8List data) async {
    File file = File(path);
    await file.writeAsBytes(data);
  }

// generate a large testfile with random data
  _generateLargeFileSync(String path, Uint8List data, int numberWrite) {
    File file = File(path);
    for (int i = 0; i < numberWrite; i++) {
      file.writeAsBytesSync(data, mode: FileMode.writeOnlyAppend);
    }
  }

  Future<List> _getFiles() async {
    //String folderName="MyFiles";
    String folderName = '';
    final directory = await getApplicationDocumentsDirectory();
    final Directory _appDocDirFolder =
    Directory('${directory.path}/${folderName}/');
    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.listSync();
    }
    return List.empty(growable: true);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}
