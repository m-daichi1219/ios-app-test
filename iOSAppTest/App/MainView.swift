//
//  MainView.swift
//  iOSAppTest
//
//  Created by daichi on 2025/10/19.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @State private var isMenuOpen = false
    @State private var selection: MenuItem = .home

    private let menuWidth: CGFloat = 280

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                contentView(for: selection)
                    .navigationTitle(selection.title)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.easeInOut) {
                                    isMenuOpen.toggle()
                                }
                            } label: {
                                Image(systemName: "line.horizontal.3")
                            }
                            .accessibilityLabel(Text("メニュー"))
                        }
                    }
            }
            .offset(x: isMenuOpen ? menuWidth : 0)
            .disabled(isMenuOpen)
            .animation(.easeInOut(duration: 0.2), value: isMenuOpen)

            if isMenuOpen {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isMenuOpen.toggle()
                        }
                    }
                    .transition(.opacity)
            }
            SideMenuView(selection: $selection, isOpen: $isMenuOpen)
                .offset(x: isMenuOpen ? 0 : -menuWidth)
                .animation(.easeInOut(duration: 0.2), value: isMenuOpen)
        }
    }

    @ViewBuilder
    private func contentView(for item: MenuItem) -> some View {
        switch item {
        case .home:
            HomeView()
        case .ble:
            BLEView()
        case .gps:
            GPSView()
        case .motion:
            MotionView()
        }
    }
}

#Preview {
    MainView()
}
