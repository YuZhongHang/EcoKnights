# AQI Map

A modern Flutter application that displays real-time Air Quality Index (AQI) data with a sleek, minimalist dark theme design.

## Screenshot
<img src="https://github.com/user-attachments/assets/dfdbd4eb-60f9-4e7a-a230-3186c8459a4d" width="300" alt="AQI Map Screenshot">

## Features

- Real-time AQI data display
- Location-based air quality monitoring
- Detailed pollutant breakdown (PM2.5, PM10, NO₂, SO₂, CO)
- Visual status indicators with color coding
- Dark theme optimized interface

## UI Components

### Main Screen (AqiScreen)
- **Location Display**: City name in large, clear typography
- **AQI Value**: Prominently displayed with dynamic color based on air quality
- **Status Indicator**: Visual representation of air quality level
- **Pollutant Details**: Bar graph visualization for each pollutant

## Technical Stack

### Architecture
- **State Management**: Flutter Riverpod with code generation (@riverpod)
- **Code Generation**: Freezed for immutable models
- **API Integration**: Retrofit for type-safe API calls
- **Environment**: flutter_dotenv for configuration

### Layer Structure
- **UI Layer**: `AqiScreen` handles the presentation using Flutter widgets
- **State Layer**: `AqiNotifier` manages state with Riverpod's AsyncNotifier
- **Repository Layer**: `AqiRepository` abstracts data operations
- **API Layer**: `AqiClient` handles API communication with Retrofit
- **Model Layer**: `AqiInfo` and related models using Freezed

### Key Components
- `AqiScreen`: Main UI with dark theme
- `AqiNotifier`: State handling with Riverpod
- `AqiRepository`: Data layer implementation
- `AqiInfo`: Freezed data models

## Getting Started

### API Key Setup
1. Visit [WAQI API Platform](https://aqicn.org/data-platform/token/) to obtain your API key
2. Create a `.env` file in the root directory:
