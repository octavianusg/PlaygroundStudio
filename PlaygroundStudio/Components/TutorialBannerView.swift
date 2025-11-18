//
//  TutorialBannerView.swift
//  PlaygroundStudio
//
//  Created by User on 18/11/25.
//
import SwiftUI

struct TutorialBannerView: View {
    var fileStep: FileStep
    
    @Binding var currentStep: Int
    
    let totalSteps: Int

    var onBack: (() -> Void)?
    var onNext: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Back button and title
                HStack(spacing: 8) {
                    Text(fileStep.title)
                        .font(.headline)
                }

                Spacer()

                // Close button
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(fileStep.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .disabled(currentStep == 1)
                .opacity(currentStep == 1 ? 0.3 : 1.0)

                // Page indicator in the center
                Spacer()
                Text("\(currentStep) of \(totalSteps)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()

                // Next button on the right
                Button(action: { onNext?() }) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 8, y: 4)
        .padding([.horizontal, .top])
    }
}
