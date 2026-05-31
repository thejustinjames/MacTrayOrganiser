//
//  OnboardingView.swift
//  MacTrayOrganiser
//
//  First-run permission request flow
//

import SwiftUI
import Combine

struct OnboardingView: View {
    @EnvironmentObject var permissionManager: PermissionManager
    @State private var currentStep: OnboardingStep = .welcome

    enum OnboardingStep {
        case welcome
        case permission
        case granted
    }

    var body: some View {
        VStack(spacing: 20) {
            switch currentStep {
            case .welcome:
                welcomeStep
            case .permission:
                permissionStep
            case .granted:
                grantedStep
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(permissionManager.$hasAccessibilityPermission) { hasPermission in
            if hasPermission && currentStep != .granted {
                withAnimation {
                    currentStep = .granted
                }
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Welcome to MacTrayOrganiser")
                .font(.title2)
                .fontWeight(.semibold)

            Text("View and organize all your menu bar icons, including those hidden by the notch.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "eye", text: "See all menu bar icons")
                FeatureRow(icon: "arrow.up.arrow.down", text: "Reorder with drag & drop")
                FeatureRow(icon: "pin", text: "Pin your favorites")
                FeatureRow(icon: "eye.slash", text: "Hide items you don't need")
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            Button(action: {
                withAnimation {
                    currentStep = .permission
                }
            }) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Accessibility Permission")
                .font(.title2)
                .fontWeight(.semibold)

            Text("MacTrayOrganiser needs Accessibility permission to read menu bar items and simulate clicks.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("To enable:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    StepRow(number: 1, text: "Click \"Open System Settings\"")
                    StepRow(number: 2, text: "Find MacTrayOrganiser in the list")
                    StepRow(number: 3, text: "Toggle the switch to enable access")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

            Spacer().frame(height: 10)

            Button(action: {
                permissionManager.requestAccessibilityPermission()
            }) {
                Text("Open System Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Check Permission Status") {
                _ = permissionManager.checkAccessibilityPermission()
            }
            .buttonStyle(.link)

            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Waiting for permission...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var grantedStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Set!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("MacTrayOrganiser now has access to your menu bar. Enjoy organizing your icons!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Start Using MacTrayOrganiser") {
                MenuBarScanner.shared.scan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.body)
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.body)
                .fontWeight(.semibold)
                .frame(width: 20, alignment: .trailing)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(PermissionManager.shared)
        .frame(width: 400, height: 500)
}
