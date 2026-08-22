//
//  CheckInView.swift
//  WaiveGO
//
//  Root screen for the kiosk. Full-screen, high-contrast, no chrome — this is meant to
//  run on an iPad mounted at the entrance, tapped by staff or a guest to start a scan.

import SwiftUI

struct CheckInView: View {
    @StateObject private var viewModel = CheckInViewModel()

    var body: some View {
        ZStack {
            background

            VStack(spacing: 32) {
                Spacer()

                switch viewModel.status {
                case .idle:
                    IdleStateView(onTap: viewModel.startScan)
                case .scanning:
                    ScanningStateView(camera: viewModel.camera)
                case .verified(let match):
                    ResultStateView(
                        tint: .green,
                        systemImage: "checkmark.circle.fill",
                        title: "Welcome, \(match.guestName)!",
                        message: "Waiver verified. Enjoy your visit!"
                    )
                case .notVerified(let reason):
                    ResultStateView(
                        tint: .red,
                        systemImage: "xmark.circle.fill",
                        title: reason.title,
                        message: reason.message
                    )
                case .error(let message):
                    ResultStateView(
                        tint: .orange,
                        systemImage: "wifi.exclamationmark",
                        title: "Check-In Unavailable",
                        message: message
                    )
                }

                Spacer()

                #if DEBUG
                debugControls
                #endif
            }
            .padding(40)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.15), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Buttons to jump straight to each result state — lets us build/demo the UI
    /// without a real camera or backend. Remove once real scanning is wired up.
    #if DEBUG
    private var debugControls: some View {
        VStack(spacing: 12) {
            Text("Debug: Simulate Result")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("No Match") { viewModel.simulateNotVerified(.noFaceMatch) }
                Button("Expired") { viewModel.simulateNotVerified(.waiverExpired(guestName: "Sam Lee")) }
                Button("No Waiver") { viewModel.simulateNotVerified(.noWaiverOnFile) }
                Button("Server Error") { viewModel.resolve(.error(message: "Couldn't reach the check-in service.")) }
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding(.bottom, 8)
    }
    #endif
}

private struct IdleStateView: View {
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 96))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(isPulsing ? 1.12 : 0.92)
                    .opacity(isPulsing ? 1.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .onAppear { isPulsing = true }
                Text("WaiveGO")
                    .font(.largeTitle.bold())
                Text("Tap to scan your face and check in")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ScanningStateView: View {
    /// Shared with CheckInViewModel, not owned here — the same camera session drives
    /// both this preview and the actual "has a face been held in frame" decision, so
    /// what you see on screen always matches what the state machine is acting on.
    @ObservedObject var camera: CameraService
    @State private var isPulsing = false

    private let circleSize: CGFloat = 320

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if camera.isAuthorized {
                    CameraPreviewView(session: camera.session)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }

                Circle()
                    .stroke(ringColor, lineWidth: 8)
                    .scaleEffect(isPulsing ? 1.08 : 0.96)
                    .opacity(isPulsing ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: camera.isFaceDetected ? 0.4 : 1.1).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }
            .frame(width: circleSize, height: circleSize)
            .onAppear {
                // The camera itself is started by CheckInViewModel.startScan() (so it
                // gets a head start before this view even appears) — just drive the
                // pulse animation here.
                isPulsing = true
            }

            Text(camera.isFaceDetected ? "Face found — hold still…" : "Looking for a face…")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: camera.isFaceDetected)
        }
    }

    private var ringColor: Color {
        camera.isFaceDetected ? .green : .accentColor
    }
}

private struct ResultStateView: View {
    let tint: Color
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 96))
                .foregroundStyle(tint)
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .transition(.opacity)
    }
}

#Preview("Idle") {
    CheckInView()
}

#Preview("Verified") {
    ResultStateView(
        tint: .green,
        systemImage: "checkmark.circle.fill",
        title: "Welcome, Jordan Rivera!",
        message: "Waiver verified. Enjoy your visit!"
    )
}
