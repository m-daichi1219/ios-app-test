import SwiftUI

struct SideMenuView: View {
    @Binding var selection: MenuItem
    @Binding var isOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メニュー").font(.headline).padding(.horizontal).padding(.top, 16)

            ForEach(MenuItem.allCases) { item in
                Button {
                    selection = item
                    withAnimation(.easeInOut) {
                        isOpen.toggle()
                    }
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(selection == item ? Color.accentColor.opacity(0.12) : .clear)
                .cornerRadius(8)
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .frame(maxWidth: 280, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .overlay(alignment: .trailing) {
            Divider()
        }
    }
}
