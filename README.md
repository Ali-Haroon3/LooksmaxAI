# LooksmaxAI

An iOS application that analyzes facial features and body metrics to provide a "Looksmaxxing" score and personalized improvement routines.

## Features

### AI Scanner
- Uses Apple Vision Framework (VNDetectFaceLandmarksRequest) for facial analysis
- Real-time face detection with guide overlay
- High-resolution photo capture for accurate analysis

### The Lab (Dashboard)
- Overall PSL score (1-10 scale)
- Radar chart visualization
- Score breakdown by category:
  - Eye Area (30%): Canthal tilt, IPD, Brow ridge
  - Bone Structure (30%): FWHR, Gonial angle, Cheekbones
  - Symmetry (20%): Eye and jaw symmetry analysis
  - Body/Softmax (20%): BMI, Waist-to-shoulder ratio, Skin

### Routine Library
- Personalized recommendations based on scan results
- Categories: Eye Area, Jawline, Skincare, Grooming, Fitness, Posture, Sleep, Nutrition
- Video/photo demonstrations for each routine
- Progress tracking

### Mathematical Analysis

**Midface Ratio:**
```
Ratio = Midface Length (Pupils to Lips) / IPD
Target: 1.00
```

**FWHR (Facial Width-to-Height Ratio):**
```
FWHR = Bizygomatic Width / Upper Face Height
Target: 1.9 - 2.2
```

**Canthal Tilt:**
```
θ = arctan((y_outer - y_inner) / (x_outer - x_inner))
Ideal: Positive tilt (> 0°)
```

## Tech Stack

- **Language:** Swift 6 / SwiftUI
- **Architecture:** MVVM
- **Computer Vision:** Apple Vision Framework
- **Persistence:** SwiftData
- **Minimum iOS:** 17.0

## Project Structure

```
LooksmaxAI/
├── Models/
│   ├── UserStats.swift         # User profile and body measurements
│   ├── FaceMetrics.swift       # Facial landmark measurements
│   ├── ScanHistory.swift       # Scan results and scores
│   └── Recommendation.swift    # Improvement recommendations
├── Services/
│   ├── CameraService.swift     # Camera capture management
│   ├── VisionAnalyzer.swift    # Vision framework analysis
│   └── ScoringEngine.swift     # PSL score calculation
├── Utilities/
│   ├── FaceMath.swift          # Mathematical calculations
│   └── DesignSystem.swift      # UI styling constants
├── Views/
│   ├── ContentView.swift       # Main navigation
│   ├── OnboardingView.swift    # User setup flow
│   ├── ScannerView.swift       # Camera/scanning interface
│   ├── ResultsView.swift       # Analysis results display
│   ├── DashboardView.swift     # The Lab dashboard
│   ├── RoutineListView.swift   # Routine library
│   ├── RoutineDetailView.swift # Individual routine details
│   ├── ProfileView.swift       # User profile management
│   └── Components/
│       └── VideoPlayerView.swift
└── Resources/
    └── RoutineLibrary.swift    # Routine database
```

## Setup

1. Open the project in Xcode 16+
2. Select your development team for signing
3. Build and run on a physical iOS device (camera required)

## Important Notes

- This app focuses on "softmaxxing" (natural grooming, fitness, and lifestyle improvements)
- All recommendations are for informational purposes only
- Not a medical device - consult healthcare professionals for health concerns
- Based on community standards from Looksmaxxing.org and related research

## Medical Disclaimer

This app is for entertainment and informational purposes only. It is NOT a medical device and should NOT be used for medical diagnosis, treatment, or health decisions. Beauty standards are subjective and culturally influenced. Self-worth is not determined by any score.
