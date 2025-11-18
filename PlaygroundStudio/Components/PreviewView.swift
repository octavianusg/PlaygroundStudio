//
//  PreviewView.swift
//  PlaygroundStudio
//
//  Created by octavianus on 18/11/25.
//

import SwiftUI

/// A view that mimics the Swift Playgrounds live preview area.
/// For now it only shows placeholder content and a mock console.
struct PreviewView: View {

    @State private var isRunning: Bool = false
    @State private var showBorders: Bool = true
    @State private var showConsole: Bool = false
    @State private var logs: [String] = [
        "Building preview…",
        "Waiting for code to run…"
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            ZStack {
                HStack(spacing: 12) {
                    previewSurface
                    if showConsole {
                        consolePanel
                            .frame(width: 260)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(16)

                // Bottom-right console toggle
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                showConsole.toggle()
                            }
                        } label: {
                            Image(systemName: "terminal.fill")
                                .font(.title3)
                                .padding(10)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 8, y: 3)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .underPageBackgroundColor))
        }
    }

    // MARK: - Header (toolbar-like) bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            Text("Live View")
                .font(.headline)

            Spacer()

            Toggle(isOn: $showBorders.animation(.easeInOut)) {
                Text("Show borders")
                    .font(.subheadline)
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .overlay(
                Text("Show borders")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 36),
                alignment: .leading
            )
            .frame(width: 150)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isRunning.toggle()
                    appendLog(isRunning ? "Started preview." : "Stopped preview.")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    Text(isRunning ? "Stop" : "Run")
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Preview surface

    private var previewSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    Group {
                        if showBorders {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                        }
                    }
                )
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: isRunning ? "sparkles" : "swift")
                    .font(.system(size: 52))
                    .foregroundColor(isRunning ? .accentColor : .orange)

                Text(isRunning ? "Your preview would render here." : "Run your code to see a live preview.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                if isRunning {
                    ProgressView()
                        .padding(.top, 4)
                }

                Spacer()

                Text("Preview placeholder")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Console

    private var consolePanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Console")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    withAnimation {
                        logs.removeAll()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if logs.isEmpty {
                        Text("No output yet.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    } else {
                        ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.footnote.monospaced())
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(8)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func appendLog(_ line: String) {
        logs.append("• \(line)")
    }
}

// MARK: - Preview

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
            .frame(height: 500)
    }
}
