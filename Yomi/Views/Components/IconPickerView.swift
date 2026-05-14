import SwiftUI
import UIKit

struct IconPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    private static let icons: [String] = [
        "newspaper.fill", "tag.fill", "folder.fill", "bookmark.fill", "star.fill",
        "globe", "building.columns.fill", "flag.fill", "mappin.and.ellipse", "person.3.fill",
        "briefcase.fill", "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "creditcard.fill",
        "laptopcomputer", "cpu.fill", "gear", "chevron.left.forwardslash.chevron.right", "wand.and.stars",
        "atom", "function", "leaf.fill", "stethoscope", "cross.case.fill",
        "sportscourt.fill", "figure.run", "gamecontroller.fill", "popcorn.fill", "film.fill",
        "music.note", "theatermasks.fill", "paintpalette.fill", "camera.fill", "photo.fill",
        "book.fill", "graduationcap.fill", "pencil.and.outline", "fork.knife", "cup.and.saucer.fill",
        "airplane", "car.fill", "house.fill", "pawprint.fill", "heart.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Self.icons, id: \.self) { name in
                        Button {
                            selection = name
                            dismiss()
                        } label: {
                            Image(systemName: name)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .foregroundStyle(selection == name ? Color.white : Color.primary)
                                .background(
                                    Circle()
                                        .fill(selection == name ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
