# sample_supabase_webrtc

Sample demo project for supabase and WebRTC

## Getting Started

### Step1. Clone Repository
Clone the repository to your local environment
```shell
git clone https://github.com/minnya/sample-supabase-webrtc.git
```

### Step2. Go to sample_supabase_webrtc
```shell
cd sample_supabase_webrtc
```

### Step3. Get dependencies
```shell
flutter pub get
```

### Step4. Update Supabase Server URL
Go to `main.dart` file, update the supabase url if necessary.

For further details about Supabase & Flutter, please refer to the official document from [here](https://pub.dev/packages/supabase_flutter)

```dart
// ...

String baseUrl = "";
String anonKey = "****"; // Replace here if necessary

void main() async{
  if(!kIsWeb && Platform.isAndroid){
    baseUrl = "http://10.0.2.2:8000";
  }else{
    baseUrl = "http://localhost:8000"; // Replace here if necessary
  }
  await Supabase.initialize(
    url: baseUrl,
    anonKey: anonKey,
  );
  runApp(const MyApp());
}

// ...
```

### Step5. Run the sample app
It's time to push the launch button.
```shell
flutter run
```