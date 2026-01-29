import SwiftUI
import SwiftData
import AVFoundation

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserStats]

    @StateObject private var cameraService = CameraService()
    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    @State private var qualityFeedback: String = "Position your face in the guide"
    @State private var showResults = false
    @State private var scanResult: ScanHistory?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Camera preview area
                    ZStack {
                        CameraPreviewView(cameraService: cameraService)
                            .aspectRatio(3/4, contentMode: .fit)
                            .cornerRadius(DesignSystem.CornerRadius.xl)
                            .overlay(
                                FaceGuideOverlay(isScanning: isScanning, progress: scanProgress)
                            )
                            .padding(DesignSystem.Spacing.lg)

                        // Quality feedback
                        VStack {
                            Spacer()
                            Text(qualityFeedback)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.surfacePrimary.opacity(0.9))
                                .cornerRadius(DesignSystem.CornerRadius.full)
                                .padding(.bottom, DesignSystem.Spacing.xl)
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }

                    Spacer()

                    // Controls
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Scan button
                        Button {
                            Task {
                                await performScan()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.surfacePrimary)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .fill(isScanning ?
                                          DesignSystem.Colors.warning :
                                          DesignSystem.Colors.accentCyan)
                                    .frame(width: 64, height: 64)

                                if isScanning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 28))
                                        .foregroundColor(DesignSystem.Colors.background)
                                }
                            }
                            .cyanGlow(intensity: isScanning ? 0 : 0.4)
                        }
                        .disabled(isScanning)

                        Text(isScanning ? "Analyzing..." : "Tap to Scan")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.textSecondary)

                        // Camera controls
                        HStack(spacing: DesignSystem.Spacing.xl) {
                            Button {
                                cameraService.switchCamera()
                            } label: {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 20))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(DesignSystem.Colors.surfaceSecondary)
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .navigationTitle("AI Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await cameraService.checkAuthorization()
                await cameraService.setupSession()
                cameraService.startSession()
            }
            .onDisappear {
                cameraService.stopSession()
            }
            .alert("Scan Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $showResults) {
                if let result = scanResult {
                    ResultsView(scanHistory: result)
                }
            }
        }
    }

    // MARK: - Scan Logic

    private func performScan() async {
        guard let user = users.first else { return }

        isScanning = true
        scanProgress = 0
        qualityFeedback = "Hold still..."

        // Animate progress
        withAnimation(.linear(duration: 2)) {
            scanProgress = 1.0
        }

        // Capture photo
        guard let image = await cameraService.capturePhoto() else {
            isScanning = false
            errorMessage = "Failed to capture image"
            showError = true
            return
        }

        qualityFeedback = "Processing..."

        do {
            // Check quality
            let quality = VisionAnalyzer.shared.checkImageQuality(image)
            if !quality.isAcceptable {
                isScanning = false
                qualityFeedback = quality.feedback
                return
            }

            // Analyze face
            let metrics = try VisionAnalyzer.shared.analyzeFace(image)

            // Calculate scores
            let result = ScoringEngine.calculateScores(from: metrics, userStats: user)

            // Generate recommendations
            let recommendationData = ScoringEngine.generateRecommendations(from: result)

            // Create scan history
            let scanHistory = ScanHistory(
                overallPSLScore: result.overallPSLScore,
                potentialMaxScore: result.potentialMaxScore,
                eyeAreaScore: result.eyeArea.total,
                boneStructureScore: result.boneStructure.total,
                symmetryScore: result.symmetry.total,
                softmaxBodyScore: result.softmaxBody.total,
                canthalTiltScore: result.eyeArea.canthalTiltScore,
                ipdScore: result.eyeArea.ipdScore,
                browRidgeScore: result.eyeArea.browRidgeScore,
                fwhrScore: result.boneStructure.fwhrScore,
                gonialAngleScore: result.boneStructure.gonialAngleScore,
                cheekboneScore: result.boneStructure.cheekboneScore,
                bmiScore: result.softmaxBody.bmiScore,
                waistToShoulderScore: result.softmaxBody.waistToShoulderScore,
                skinTextureScore: result.softmaxBody.skinTextureScore
            )

            scanHistory.userStats = user
            scanHistory.faceMetrics = metrics
            scanHistory.scanImageData = image.jpegData(compressionQuality: 0.8)

            // Add recommendations
            for recData in recommendationData {
                let recommendation = recData.toRecommendation()
                recommendation.scanHistory = scanHistory
                scanHistory.recommendations.append(recommendation)
            }

            modelContext.insert(scanHistory)
            try modelContext.save()

            scanResult = scanHistory
            isScanning = false
            qualityFeedback = "Scan complete!"

            // Navigate to results
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showResults = true
            }

        } catch {
            isScanning = false
            errorMessage = error.localizedDescription
            showError = true
            qualityFeedback = "Position your face in the guide"
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraService.previewLayer
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Face Guide Overlay

struct FaceGuideOverlay: View {
    let isScanning: Bool
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let ovalWidth = width * 0.7
            let ovalHeight = height * 0.65

            ZStack {
                // Darkened edges
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Canvas { context, size in
                            context.fill(
                                Path(CGRect(origin: .zero, size: size)),
                                with: .color(.white)
                            )
                            context.blendMode = .destinationOut
                            let ovalRect = CGRect(
                                x: (size.width - ovalWidth) / 2,
                                y: (size.height - ovalHeight) / 2,
                                width: ovalWidth,
                                height: ovalHeight
                            )
                            context.fill(
                                Path(ellipseIn: ovalRect),
                                with: .color(.white)
                            )
                        }
                    )

                // Face guide oval
                Ellipse()
                    .strokeBorder(
                        isScanning ?
                        DesignSystem.Colors.accentCyan :
                        Color.white.opacity(0.6),
                        lineWidth: isScanning ? 3 : 2
                    )
                    .frame(width: ovalWidth, height: ovalHeight)
                    .overlay(
                        // Scanning animation
                        Ellipse()
                            .trim(from: 0, to: progress)
                            .stroke(
                                DesignSystem.Colors.accentCyan,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: ovalWidth, height: ovalHeight)
                            .rotationEffect(.degrees(-90))
                            .opacity(isScanning ? 1 : 0)
                    )

                // Corner guides
                VStack {
                    HStack {
                        CornerGuide(rotation: 0)
                        Spacer()
                        CornerGuide(rotation: 90)
                    }
                    Spacer()
                    HStack {
                        CornerGuide(rotation: 270)
                        Spacer()
                        CornerGuide(rotation: 180)
                    }
                }
                .frame(width: ovalWidth * 0.85, height: ovalHeight * 0.85)
            }
        }
    }
}

struct CornerGuide: View {
    let rotation: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(DesignSystem.Colors.accentCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    ScannerView()
        .modelContainer(for: [UserStats.self, ScanHistory.self], inMemory: true)
}
