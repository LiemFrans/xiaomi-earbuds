import SwiftUI

// MARK: - Component Catalog

/// A comprehensive preview catalog showcasing all Design System components
/// with sample data. Use Xcode previews to view in both Light and Dark modes.
struct ComponentCatalog: View {
    @State private var ancMode: ANCMode = .noiseCancellation
    @State private var depth: Double = 0.65
    @State private var wearDetection = true
    @State private var inEarDetection = false
    @State private var doublePressLeft: GestureAction = .playPause
    @State private var doublePressRight: GestureAction = .nextSong
    @State private var codec: AudioCodec = .ldac
    @State private var soundMode: SoundMode = .balanced
    @State private var isConnected = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {

                // MARK: - Device Header

                catalogSection("1. DeviceHeaderView") {
                    DeviceHeaderView()
                }

                // MARK: - Connection Status

                catalogSection("2. ConnectionStatusDot") {
                    HStack(spacing: Spacing.xl) {
                        ConnectionStatusDot(isConnected: true)
                        ConnectionStatusDot(isConnected: false)
                    }
                }

                // MARK: - Battery Gauges

                catalogSection("3. BatteryGaugeView") {
                    VStack(spacing: Spacing.sm) {
                        BatteryGaugeView(label: "Left", level: 92)
                        BatteryGaugeView(label: "Right", level: 15)
                        BatteryGaugeView(label: "Case", level: 5)
                    }
                }

                // MARK: - ANC Mode Picker

                catalogSection("4. ANCModePicker") {
                    ANCModePicker(selectedMode: $ancMode)
                }

                // MARK: - Depth Slider

                catalogSection("5. DepthSlider") {
                    DepthSlider(depth: $depth, label: "Noise Cancellation Depth")
                }

                // MARK: - Setting Toggle Rows

                catalogSection("6. SettingToggleRow") {
                    VStack(spacing: Spacing.sm) {
                        SettingToggleRow(
                            title: "Wear Detection",
                            description: "Automatically pause when you remove an earbud.",
                            isOn: $wearDetection
                        )
                        Divider()
                        SettingToggleRow(
                            title: "In-Ear Detection",
                            description: "Detect earbuds placement for auto-connect.",
                            isOn: $inEarDetection
                        )
                    }
                }

                // MARK: - Gesture Picker Rows

                catalogSection("7. GesturePickerRow") {
                    VStack(spacing: Spacing.sm) {
                        GesturePickerRow(
                            gestureName: "Double press left",
                            selectedAction: $doublePressLeft
                        )
                        Divider()
                        GesturePickerRow(
                            gestureName: "Double press right",
                            selectedAction: $doublePressRight
                        )
                    }
                }

                // MARK: - Codec Radio Group

                catalogSection("8. CodecRadioGroup") {
                    CodecRadioGroup(selectedCodec: $codec)
                }

                // MARK: - Sound Mode Radio Group

                catalogSection("9. SoundModeRadioGroup") {
                    SoundModeRadioGroup(selectedMode: $soundMode)
                }

                // MARK: - Section Card

                catalogSection("10. SectionCard") {
                    SectionCard(header: "About Device") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            LabeledContent("Firmware", value: "v2.1.4")
                            LabeledContent("Serial Number", value: "XM-RB8P-001")
                            LabeledContent("Bluetooth", value: "5.4")
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .frame(
            minWidth: Spacing.Window.minWidth,
            idealWidth: Spacing.Window.defaultWidth,
            minHeight: Spacing.Window.minHeight
        )
    }

    @ViewBuilder
    private func catalogSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(TypographyTokens.captionMedium)
                .foregroundStyle(ColorTokens.labelTertiary)
                .textCase(.uppercase)

            GroupBox {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Previews
