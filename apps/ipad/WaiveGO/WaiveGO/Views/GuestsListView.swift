//
//  GuestsListView.swift
//  WaiveGO
//
//  Staff-facing: shows everyone currently enrolled (a face linked to a waiver — real
//  or, for now, test). There's no "unlinked waiver" to show yet without Smartwaiver
//  access — every row here is inherently linked, since enrollment is what creates
//  the row at all (see services/api/src/routes/guests.ts). Once Smartwaiver access
//  exists, this is where real unlinked waivers with a "link a face" action would
//  show up alongside these.
//
//  No access control on this screen yet — same known gap as the API endpoints it
//  calls (see services/api/README.md). Fine while nothing is public-facing; needs
//  to change before this app ships to a real front-of-house iPad.

import SwiftUI

struct GuestsListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var guests: [Guest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingEnroll = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Guests")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingEnroll = true
                        } label: {
                            Label("Add Test Guest", systemImage: "person.badge.plus")
                        }
                    }
                }
                .task { await load() }
                .refreshable { await load() }
                .sheet(isPresented: $showingEnroll) {
                    EnrollGuestView { Task { await load() } }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && guests.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage, guests.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Retry") { Task { await load() } }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if guests.isEmpty {
            ContentUnavailableView(
                "No Guests Enrolled",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Tap \"Add Test Guest\" to enroll someone.")
            )
        } else {
            List(guests) { guest in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(guest.fullName)
                            .font(.headline)
                        if guest.isTestGuest {
                            Text("TEST")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Label("Linked", systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                    }
                    Text(guest.smartwaiverWaiverId)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
        }
    }

    private func load() async {
        isLoading = true
        do {
            guests = try await APIClient.shared.listGuests()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    GuestsListView()
}
