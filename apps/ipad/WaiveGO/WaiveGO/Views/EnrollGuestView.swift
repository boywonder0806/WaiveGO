//
//  EnrollGuestView.swift
//  WaiveGO
//
//  Staff-facing: enrolls a new test guest (name + a deliberately-captured photo, no
//  Smartwaiver waiver required — see services/api/src/routes/guests.ts's test mode).
//  Unlike the kiosk's automatic hold-to-scan flow, capture here is a manual shutter
//  press — enrollment is a deliberate staff action, not something to trigger on
//  whoever happens to walk in front of the camera.

import SwiftUI

struct EnrollGuestView: View {
    var onEnrolled: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraService()

    @State private var fullName = ""
    @State private var capturedImage: UIImage?
    @State private var capturedData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && capturedData != nil && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Guest Name") {
                    TextField("Full name", text: $fullName)
                        .textInputAutocapitalization(.words)
                }

                Section("Photo") {
                    photoArea
                    if capturedData != nil {
                        Button("Retake") {
                            capturedImage = nil
                            capturedData = nil
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("Test enrollment — not linked to a real Smartwaiver waiver. Once Smartwaiver access is set up, real guests will enroll from an actual signed waiver instead.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Test Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear { camera.start() }
            .onDisappear { camera.stop() }
        }
    }

    @ViewBuilder
    private var photoArea: some View {
        ZStack {
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if camera.isAuthorized {
                CameraPreviewView(session: camera.session)
            } else {
                Color(.secondarySystemBackground)
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottom) {
            if capturedData == nil {
                Button {
                    capture()
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.white, Color.accentColor)
                        .shadow(radius: 4)
                }
                .padding(.bottom, 8)
            }
        }
        .listRowInsets(EdgeInsets())
    }

    private func capture() {
        guard let data = camera.captureStillJPEG(), let image = UIImage(data: data) else { return }
        capturedData = data
        capturedImage = image
    }

    private func save() async {
        guard let capturedData else { return }
        isSaving = true
        errorMessage = nil
        do {
            _ = try await APIClient.shared.enrollTestGuest(
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                imageData: capturedData
            )
            isSaving = false
            onEnrolled()
            dismiss()
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EnrollGuestView(onEnrolled: {})
}
