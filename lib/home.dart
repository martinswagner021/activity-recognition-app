import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  static const int windowSize = 200;
  static const int numFeatures = 4;

  final List<String> _activityLabels = [
    'Downstairs',
    'Jogging',
    'Sitting',
    'Standing',
    'Upstairs',
    'Walking',
  ];

  // Downstairs  Jogging  Sitting  Standing  Upstairs  Walking

  List<double>? _accelerometerValues;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late Interpreter _interpreter;
  bool _modelLoaded = false;

  final List<List<double>> _dataWindow = [];
  String _predictedActivity = "Initializing...";
  List<double> _outputProbabilities = [];
  final FlutterTts _speaker = FlutterTts();

  _magnitude(double x, double y, double z) {
    return math.sqrt(math.pow(x, 2) + math.pow(y, 2) + math.pow(z, 2));
  }

  @override
  void initState() {
    super.initState();
    _loadmodel();
    _startListening();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    if (_modelLoaded) {
      _interpreter.close();
    }
    super.dispose();
  }

  void _loadmodel() {
    // load from assets
    Interpreter.fromAsset('assets/model.tflite').then((value) {
      setState(() {
        _interpreter = value;
        _modelLoaded = true;
      });
      print(_interpreter.getInputTensors());
      print(_interpreter.getOutputTensors());
    });
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: Duration(milliseconds: 50),
    ).listen(
      (AccelerometerEvent event) {
        if (!_modelLoaded) return;

        setState(() {
          _accelerometerValues = <double>[event.x, event.y, event.z];
        });

        // Add current accelerometer reading to the window
        _dataWindow.add([
          event.x,
          event.y,
          event.z,
          _magnitude(event.x, event.y, event.z),
        ]);

        // If window is full, run inference
        if (_dataWindow.length == windowSize) {
          _runInference();
          _dataWindow.clear(); // Clear window for next set of readings
          // Alternatively, use a sliding window:
          // _dataWindow.removeAt(0);
        }
      },
      onError: (error) {
        print("Sensor error: $error");
        setState(() {
          _predictedActivity = "Sensor error.";
        });
      },
      cancelOnError: true,
    );
  }

  Future<void> _runInference() async {
    if (!_modelLoaded || _dataWindow.length < windowSize) {
      print("Model not loaded or data window not full.");
      return;
    }

    // 2) Prepare your output buffer:
    var outShape = _interpreter.getOutputTensor(0).shape; // e.g. [1,6]
    int outSize = outShape.reduce((a, b) => a * b);
    var outputBuffer = List.filled(outSize, 0.0).reshape(outShape);

    // --- 3. Run inference ---
    try {
      // The input to interpreter.run should be a List<Object> or an Object.
      // If your model has one input, it's `[inputBytesList]` or `inputBytesList.buffer`
      // If your input tensor is e.g. [1, 128, 3], you need to provide a List<List<List<double>>>
      // or a flat Float32List that the interpreter can map to this shape.
      // Let's try providing the _dataWindow directly, assuming tflite_flutter can handle List<List<double>>
      // if the shape matches. Or, provide the flattened Float32List.

      // Option A: Using the original _dataWindow (List<List<double>>) wrapped in another list for batch=1
      // This assumes the interpreter can map List<List<double>> to a [1, windowSize, numFeatures] tensor
      // if the input tensor is defined as such.
      var inputForModel = [_dataWindow]; // Becomes [1, windowSize, numFeatures]

      // Option B: Using the flattened Float32List.
      // This is often more robust if the model expects a flat buffer that it internally reshapes.
      // var inputForModel = inputBytes.buffer; // Pass the ByteBuffer
      // Or, if the interpreter expects a List<Object> where each Object is an input tensor:
      // var inputForModel = [inputBytes.buffer.asFloat32List()]; // This might be needed

      // Let's check the input tensor type. If it's FLOAT32, Float32List is good.
      // The structure (nested lists vs flat list) depends on how tflite_flutter maps it.
      // The `_interpreter.run(inputs, outputs)` method expects:
      // inputs: A List<Object>, where each Object is an input tensor.
      // outputs: A Map<int, Object>, where the key is the output tensor index and Object is the buffer.

      // We'll use the flattened list for input, which is common.
      // The interpreter will map this flat list to the input tensor's shape.
      Map<int, Object> outputs = {0: outputBuffer}; // Output tensor at index 0
      _interpreter.runForMultipleInputs([
        inputForModel,
      ], outputs); // Pass input as List<Object>

      // --- 4. Post-process the output ---
      // outputBuffer now contains the prediction.
      // If outputBuffer is List<List<double>> (e.g. [[prob1, prob2, ...]]), take the first element.
      List<double> probabilities;
      if (outputBuffer.isNotEmpty && outputBuffer[0] is List) {
        probabilities =
            (outputBuffer[0] as List).map((e) => e as double).toList();
      } else {
        print("Unexpected outputBuffer format: ${outputBuffer.runtimeType}");
        return;
      }

      // Find the index with the highest probability
      double maxProb = 0.0;
      int predictedIndex = -1;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedIndex = i;
        }
      }

      setState(() {
        if (predictedIndex != -1 && predictedIndex < _activityLabels.length) {
          _predictedActivity = _activityLabels[predictedIndex];
          _speaker.speak(_activityLabels[predictedIndex]);
        } else if (predictedIndex != -1) {
          _predictedActivity = "Unknown Label (Index: $predictedIndex)";
        } else {
          _predictedActivity = "No prediction";
        }
        _outputProbabilities = probabilities; // Store for display
      });
    } catch (e) {
      print("Error running inference: $e");
      setState(() {
        _predictedActivity = "Error in inference.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accX = _accelerometerValues?[0].toStringAsFixed(2) ?? 'N/A';
    final accY = _accelerometerValues?[1].toStringAsFixed(2) ?? 'N/A';
    final accZ = _accelerometerValues?[2].toStringAsFixed(2) ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text("Activity Recognition"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Accelerometer:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'X: $accX, Y: $accY, Z: $accZ',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Text(
                'Data Window: ${_dataWindow.length}/$windowSize samples',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 40),
              Text(
                'Predicted Activity:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              if (!_modelLoaded)
                CircularProgressIndicator()
              else
                Text(
                  _predictedActivity,
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 20),
              if (_outputProbabilities.isNotEmpty)
                Text(
                  'Probabilities:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              if (_outputProbabilities.isNotEmpty)
                ...List.generate(_activityLabels.length, (index) {
                  if (index < _outputProbabilities.length) {
                    return Text(
                      '${_activityLabels[index]}: ${_outputProbabilities[index].toStringAsFixed(3)}',
                      style: TextStyle(fontSize: 14),
                    );
                  }
                  return SizedBox.shrink();
                }),
            ],
          ),
        ),
      ),
    );
  }
}
