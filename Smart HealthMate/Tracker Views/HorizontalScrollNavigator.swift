//
//  HorizontalScrollNavigator.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct HorizontalScrollNavigator: View {
    let panels: [PanelType] = PanelType.allCases
    @Binding var activePanel: PanelType
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(panels) { panel in
                        Button(action: {
                            activePanel = panel
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: panel.systemImageName)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(activePanel == panel ? .blue : .gray)
                                    .scaleEffect(activePanel == panel ? 1.1 : 1.0)
                                    .animation(.easeOut(duration: 0.2), value: activePanel)

                                Text(panel.displayName)
                                    .font(.caption2)
                                    .foregroundColor(activePanel == panel ? .blue : .gray)
                            }
                            .frame(minWidth: 60)
                        }
                        .accessibilityIdentifier(panel.accessibilityID) // Add accessibility identifier
                    }
                }
                .frame(minWidth: geo.size.width, alignment: .center) // <– THIS centers the content
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.white.opacity(0.95))
            .shadow(radius: 5, x: 0, y: -2)
        }
        .frame(height: 80)
    }
}

//#Preview {
//    HorizontalScrollNavigator()
//}
