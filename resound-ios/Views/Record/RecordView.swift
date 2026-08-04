import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Full-screen audio capture: a live level waveform under a large timer,
/// with cancel / pause / stop transport. Stopping hands the finished temp
/// file to `SaveRecordingSheet`.
struct RecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var recorder = AudioRecorderService()
    @State private var pending: PendingRecording?
    @State private var isDiscardDialogPresented = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if recorder.state == .denied {
                deniedView
            } else {
                recordingLayout
            }
        }
        .task {
            try? await recorder.requestPermissionAndStart()
            if recorder.state == .recording {
                lightImpact()
            }
        }
        // Keep the screen awake while a take is open; every exit path runs
        // through onDisappear, which restores the idle timer.
        .onChange(of: recorder.state, initial: true) { _, state in
            UIApplication.shared.isIdleTimerDisabled = state == .recording || state == .paused
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .confirmationDialog(
            "Discard recording?",
            isPresented: $isDiscardDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                recorder.discard()
                dismiss()
            }
            Button("Keep recording", role: .cancel) {}
        } message: {
            Text("This moment won't be saved.")
        }
        .sheet(item: $pending) { pending in
            SaveRecordingSheet(pending: pending) {
                self.pending = nil
                dismiss()
            }
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Recording layout

    private var recordingLayout: some View {
        VStack(spacing: 0) {
            statusBadge
                .padding(.top, 24)

            Spacer()

            Text(Format.duration(recorder.elapsed))
                .font(.body(64, .light, relativeTo: .largeTitle))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 24)
                .foregroundStyle(Color.appForeground)

            LiveWaveformView(levels: recorder.levels)
                .frame(height: 120)
                .padding(.top, 44)
                .padding(.horizontal, 24)

            Spacer()

            controls
                .padding(.horizontal, 36)
                .padding(.bottom, 32)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(recorder.state == .paused ? Color.appMutedForeground : Color.appDestructive)
                .frame(width: 8, height: 8)
                .opacity(isPulsing ? 0.35 : 1)
                .scaleEffect(isPulsing ? 0.8 : 1)
            Text(recorder.state == .paused ? "Paused" : "Recording")
                .font(.body(10, .semibold, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundStyle(Color.appMutedForeground)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .overlay(Capsule().strokeBorder(Color.appBorder))
        .animation(.settle, value: recorder.state)
        .accessibilityElement(children: .combine)
        // Pulse the dot only while actively recording; the dot holds steady
        // under Reduce Motion (state is still conveyed by color and text).
        .onChange(of: shouldPulse, initial: true) { _, pulses in
            if pulses {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.default) {
                    isPulsing = false
                }
            }
        }
    }

    private var shouldPulse: Bool {
        recorder.state == .recording && !reduceMotion
    }

    /// Light tap for transport moments — start, pause/resume, stop.
    private func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var controls: some View {
        HStack {
            Button {
                if recorder.elapsed > 0 {
                    isDiscardDialogPresented = true
                } else {
                    recorder.discard()
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.appForeground)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.appMuted))
            }
            .accessibilityLabel("Cancel recording")

            Spacer()

            Button {
                lightImpact()
                withAnimation(.settle) {
                    if recorder.state == .recording {
                        recorder.pause()
                    } else {
                        recorder.resume()
                    }
                }
            } label: {
                Image(systemName: recorder.state == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appForeground)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.appMuted))
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(recorder.state == .paused ? "Resume recording" : "Pause recording")
            .disabled(recorder.state == .idle)

            Spacer()

            Button {
                if let result = recorder.stop() {
                    lightImpact()
                    pending = PendingRecording(url: result.url, duration: result.duration)
                }
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.appPrimaryForeground)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.appPrimary))
            }
            .accessibilityLabel("Stop and save")
            .disabled(recorder.state == .idle)
        }
    }

    // MARK: - Permission denied

    private var deniedView: some View {
        VStack(spacing: 0) {
            Image(systemName: "mic.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.appMutedForeground)

            Text("Microphone access is off")
                .font(.display(22, .semibold, relativeTo: .title2))
                .foregroundStyle(Color.appForeground)
                .padding(.top, 20)

            Text("Allow microphone access in Settings to capture your lesson moments.")
                .font(.body(15, relativeTo: .subheadline))
                .foregroundStyle(Color.appMutedForeground)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.body(14, .medium, relativeTo: .subheadline))
                    .foregroundStyle(Color.appPrimaryForeground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.appPrimary))
            }
            .buttonStyle(.plain)
            .padding(.top, 28)

            Button("Not now") {
                dismiss()
            }
            .font(.body(14, relativeTo: .subheadline))
            .foregroundStyle(Color.appMutedForeground)
            .padding(.top, 16)
        }
        .padding(32)
    }
}

// MARK: - Save sheet

/// A finished temp recording waiting to be titled and persisted.
struct PendingRecording: Identifiable {
    let id = UUID()
    let url: URL
    let duration: TimeInterval
}

/// Title-and-save step after stopping a recording. Save copies the temp
/// file into the store; Discard deletes it.
struct SaveRecordingSheet: View {
    @Environment(RecordingStore.self) private var store

    let pending: PendingRecording
    /// Called after saving or discarding — dismisses the whole record flow.
    let onComplete: () -> Void

    @State private var title = Format.defaultTitle()
    @State private var isSaveFailedPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.body(16))
                } footer: {
                    Text("\(Format.duration(pending.duration)) captured — name it so it's easy to find again.")
                }
            }
            .navigationTitle("Save recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive) {
                        try? FileManager.default.removeItem(at: pending.url)
                        onComplete()
                    }
                    .foregroundStyle(Color.appDestructive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .alert("Couldn't save", isPresented: $isSaveFailedPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong while saving — your recording is still here, so try again.")
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try store.create(
                copying: pending.url,
                kind: .audio,
                title: trimmed.isEmpty ? Format.defaultTitle() : trimmed,
                contentType: .mpeg4Audio,
                duration: pending.duration
            )
            try? FileManager.default.removeItem(at: pending.url)
            onComplete()
        } catch {
            isSaveFailedPresented = true
        }
    }
}
