# Flutter Robot Face Animator

A highly performant and expressive animated robot face, built with Flutter's `CustomPainter`. This widget provides a set of lively, neon-style animations designed to run smoothly on a wide range of devices.

The face is designed to be driven by external data, making it a perfect UI for IoT projects, smart assistants, or any application that needs to display a status with personality.

<!-- 
  **ACTION REQUIRED:** Create a GIF of your app!
  1. Run the app on an emulator/simulator.
  2. Use a screen recorder (like QuickTime on Mac or OBS Studio on Windows).
  3. Convert the video to a GIF using a site like ezgif.com.
  4. Place the GIF in your project folder (e.g., in a new `assets/images` folder) and change the link below.
-->
![Robot Face Animation GIF](https://raw.githubusercontent.com/your-username/your-repo-name/main/assets/images/app_demo.gif)


## Features

- **10 Unique Emotional States:** Covers a wide range of statuses from Happy to Disconnected.
- **High-Performance:** Built with `CustomPainter` and optimized to run smoothly on low-end hardware.
- **Advanced Idle Animations:** All active emotional states feature a subtle "look around" and "tilt" animation, making the robot feel constantly alive.
- **Special Blink Animation:** The `Happy` state includes a unique, expressive blink.
- **Data-Driven:** Controlled by a simple `PodEmotionalState` enum, making it easy to link to an API.


## Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    ```

2.  **Navigate into the project directory:**
    ```bash
    cd your-repo-name
    ```

3.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## How to Use

The core of this project is the `AnimatedPodFace` widget. To use it, simply pass it a `PodEmotionalState` value from your app's state.

**Example Widget:** `AnimatedPodFace(state: _currentFaceState)`

## API Integration & Logic

The face is designed to be driven by data from a sensor array or an API. The logic to convert this data into an emotional state lives in your main screen (`pod_face_screen.dart` in this project).

#### Recommended JSON Structure

An API endpoint should provide a payload similar to this:

```json
{
  "temperature": 24.5,
  "moisture": 750,
  "waterLevel": "OK",
  "nutrientLevel": "LOW",
  "ledStatus": "ON",
  "coverAngle1": 85.0,
  "coverAngle2": 86.0,
  "coverAngle3": 84.0
}
Mapping Data to an Emotion

First, parse the JSON into a PodStatus model object. Then, use a logic function to determine the most important state to display. This function establishes the robot's personality by prioritizing certain conditions over others.

// This function lives in pod_face_screen.dart
PodEmotionalState _determineStateFromStatus(PodStatus status) {
  // Priority 1: Critical Warnings
  if (status.waterLevel == 'LOW') return PodEmotionalState.thirsty;
  if (status.nutrientLevel == 'LOW') return PodEmotionalState.needsNutrients;
  if (status.temperature > 30.0) return PodEmotionalState.hot;
  if (status.moisture > 900) return PodEmotionalState.thirstySoil;
  
  // Priority 2: Environmental States
  if (status.ledStatus == 'OFF') return PodEmotionalState.sleeping;
  double avgAngle = (status.coverAngle1 + status.coverAngle2 + status.coverAngle3) / 3.0;
  if (avgAngle < 45) return PodEmotionalState.hidingFromLight;
  if (avgAngle > 75) return PodEmotionalState.sunbathing;

  // Default: If everything is fine, the robot is happy
  return PodEmotionalState.happy;
}

State Reference Table
Enum Value	Robot Expression	Trigger Condition (Example)
sleeping	Sceptic (-- --)	ledStatus is OFF
waking	Opening (■ ■)	Transition from sleeping to happy
happy	Blinking Neutral	Default state when all conditions are normal
thirsty	Sad	waterLevel is LOW
needsNutrients	Denying (> <)	nutrientLevel is LOW
hot	Angry	temperature is too high
thirstySoil	Tired	moisture reading is too high (dry)
hidingFromLight	Denying (> <)	Cover angles are closed
sunbathing	In Love (♥ ♥)	Cover angles are fully open
disconnected	Broken (X X)	API connection fails