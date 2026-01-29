import SwiftUI
import AVKit

/// VideoPlayerView: Custom video player for routine demonstrations
struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 1
    @State private var showControls = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video layer
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            setupPlayer()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accentCyan))
                        )
                }

                // Custom controls overlay
                if showControls {
                    VStack {
                        Spacer()

                        // Progress bar
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            // Scrubber
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Track
                                    Rectangle()
                                        .fill(DesignSystem.Colors.surfaceTertiary)
                                        .frame(height: 4)
                                        .cornerRadius(2)

                                    // Progress
                                    Rectangle()
                                        .fill(DesignSystem.Colors.accentCyan)
                                        .frame(width: geo.size.width * progress, height: 4)
                                        .cornerRadius(2)

                                    // Scrubber handle
                                    Circle()
                                        .fill(DesignSystem.Colors.accentCyan)
                                        .frame(width: 12, height: 12)
                                        .offset(x: geo.size.width * progress - 6)
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let newProgress = value.location.x / geo.size.width
                                            progress = max(0, min(1, newProgress))
                                            let seekTime = CMTime(seconds: duration * progress, preferredTimescale: 600)
                                            player?.seek(to: seekTime)
                                        }
                                )
                            }
                            .frame(height: 12)

                            // Time labels
                            HStack {
                                Text(formatTime(progress * duration))
                                Spacer()
                                Text(formatTime(duration))
                            }
                            .font(DesignSystem.Typography.mono(12))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Play/Pause overlay
                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 8)
                    }
                }
            }
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls.toggle()
                }
            }
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        let newPlayer = AVPlayer(url: url)
        self.player = newPlayer

        // Get duration
        if let item = newPlayer.currentItem {
            Task {
                let duration = try? await item.asset.load(.duration)
                if let duration = duration {
                    self.duration = CMTimeGetSeconds(duration)
                }
            }
        }

        // Observe progress
        newPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            guard duration > 0 else { return }
            progress = CMTimeGetSeconds(time) / duration
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Image Viewer for Photo Demonstrations

struct DemonstrationImageView: View {
    let imageName: String
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                scale = max(1, min(scale, 3))
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        scale = scale > 1 ? 1 : 2
                    }
                }
        }
        .background(DesignSystem.Colors.surfaceSecondary)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - Media Gallery View

struct MediaGalleryView: View {
    let items: [MediaItem]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Main viewer
            TabView(selection: $selectedIndex) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]

                    Group {
                        switch item.type {
                        case .video(let url):
                            VideoPlayerView(url: url)
                        case .image(let name):
                            DemonstrationImageView(imageName: name)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 250)

            // Page indicators
            if items.count > 1 {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(items.indices, id: \.self) { index in
                        Circle()
                            .fill(selectedIndex == index ?
                                  DesignSystem.Colors.accentCyan :
                                  DesignSystem.Colors.surfaceTertiary)
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation { selectedIndex = index }
                            }
                    }
                }
            }

            // Item info
            if !items.isEmpty {
                let currentItem = items[selectedIndex]
                Text(currentItem.caption)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Media Item

struct MediaItem: Identifiable {
    let id = UUID()
    let type: MediaType
    let caption: String

    enum MediaType {
        case video(URL)
        case image(String)
    }
}

// MARK: - Before/After Comparison View

struct BeforeAfterView: View {
    let beforeImage: String
    let afterImage: String
    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // After image (full)
                Image(afterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Before image (masked)
                Image(beforeImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                            Spacer(minLength: 0)
                        }
                    )

                // Slider
                VStack {
                    Spacer()
                        .frame(height: 0)
                }
                .frame(width: 4)
                .background(Color.white)
                .shadow(radius: 4)
                .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            sliderPosition = max(0, min(1, value.location.x / geometry.size.width))
                        }
                )

                // Labels
                HStack {
                    Text("BEFORE")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(DesignSystem.CornerRadius.small)

                    Spacer()

                    Text("AFTER")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(height: geometry.size.height, alignment: .top)
            }
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .clipped()
        }
    }
}

#Preview {
    VStack {
        VideoPlayerView(url: URL(string: "https://example.com/video.mp4")!)
            .frame(height: 200)

        BeforeAfterView(beforeImage: "before", afterImage: "after")
            .frame(height: 200)
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
