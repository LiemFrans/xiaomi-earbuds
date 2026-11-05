import SwiftUI

// MARK: - Spatial Audio Page

/// Spatial audio settings: immersive sound, audio quality, head tracking, scene rendering.
struct SpatialAudioPage: View {
    @Environment(SpatialAudioViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        Form {
            // MARK: Immersive Sound
            Section {
                SettingToggleRow(
                    title: "Immersive Sound",
                    description: "Creates a wider soundstage for a more spatial listening experience.",
                    isOn: $vm.immersiveSound
                )
            }

            // MARK: Audio Quality
            Section("Audio Quality") {
                Picker("Audio Quality", selection: $vm.audioQuality) {
                    ForEach(AudioQuality.allCases) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Spatial audio quality")

                qualityDescription
            }

            // MARK: Head Tracking
            Section {
                SettingToggleRow(
                    title: "Track Head Movement",
                    description: "Uses built-in sensors to anchor audio to a fixed point as you move your head. Works best with spatial audio content.",
                    isOn: $vm.headTracking
                )
            }

            // MARK: Scene Rendering
            Section("Scene Rendering") {
                Picker("Scene Rendering", selection: $vm.sceneRendering) {
                    ForEach(SceneRendering.allCases) { scene in
                        Text(scene.displayName).tag(scene)
                    }
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Scene rendering preset")

                Text("Choose a rendering preset optimised for different types of content.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Spatial Audio")
    }

    @ViewBuilder
    private var qualityDescription: some View {
        switch vm.audioQuality {
        case .xiaomiDimensional:
            Text("Xiaomi Dimensional Audio provides an immersive surround experience using proprietary spatial algorithms.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .dolbyAudio:
            Text("Dolby Audio delivers rich, clear, and powerful sound with industry-standard spatial processing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview
