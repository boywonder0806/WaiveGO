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
                    ScanningStateView()
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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 96))
                    .foregroundStyle(Color.accentColor)
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
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.extraLarge)
            Text("Scanning…")
                .font(.title2.weight(.medium))
                .foregroundStyle(.secondary)
        }
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
