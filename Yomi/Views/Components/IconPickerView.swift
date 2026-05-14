import SwiftUI
import UIKit

struct IconPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    private struct IconSection {
        let title: String
        let icons: [String]
    }

    private static let sections: [IconSection] = [
        IconSection(title: "General", icons: [
            "newspaper.fill", "tag.fill", "folder.fill", "bookmark.fill", "star.fill",
        ]),
        IconSection(title: "Apple", icons: [
            "applelogo", "iphone", "ipad", "macbook", "desktopcomputer",
            "applewatch", "airpods", "appletv.fill", "homepod.fill", "visionpro",
            "applepencil",
        ]),
        IconSection(title: "Development", icons: [
            "swift", "apple.terminal.fill", "chevron.left.forwardslash.chevron.right", "curlybraces", "curlybraces.square.fill",
            "keyboard.fill", "command", "option", "laptopcomputer", "cpu.fill",
            "memorychip.fill", "server.rack", "externaldrive.fill", "internaldrive.fill", "network",
            "wifi", "antenna.radiowaves.left.and.right", "arrow.triangle.branch", "arrow.triangle.merge", "arrow.triangle.pull",
            "hammer.fill", "wrench.and.screwdriver.fill", "gear", "ant.fill", "ladybug.fill",
            "cloud.fill", "icloud.fill", "sparkles", "brain", "point.3.connected.trianglepath.dotted",
            "puzzlepiece.extension.fill", "lock.shield.fill", "key.fill", "checkmark.shield.fill", "cylinder.split.1x2.fill",
            "tablecells.fill", "chart.bar.fill", "chart.xyaxis.line", "waveform.path.ecg", "app.badge.fill",
            "apps.iphone", "doc.text.fill", "text.book.closed.fill",
        ]),
        IconSection(title: "News & World", icons: [
            "globe", "building.columns.fill", "flag.fill", "mappin.and.ellipse", "person.3.fill",
        ]),
        IconSection(title: "Business", icons: [
            "briefcase.fill", "dollarsign.circle.fill", "chart.line.uptrend.xyaxis", "banknote.fill", "creditcard.fill",
        ]),
        IconSection(title: "Science & Health", icons: [
            "atom", "function", "leaf.fill", "stethoscope", "cross.case.fill",
            "lightbulb.fill", "bolt.fill",
        ]),
        IconSection(title: "Entertainment", icons: [
            "sportscourt.fill", "figure.run", "gamecontroller.fill", "popcorn.fill", "film.fill",
            "music.note", "theatermasks.fill", "paintpalette.fill", "camera.fill", "photo.fill",
        ]),
        IconSection(title: "Lifestyle", icons: [
            "book.fill", "graduationcap.fill", "pencil.and.outline", "fork.knife", "cup.and.saucer.fill",
            "airplane", "car.fill", "house.fill", "pawprint.fill", "heart.fill",
        ]),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Self.sections, id: \.title) { section in
                    Section {
                        ForEach(section.icons, id: \.self) { name in
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
                    } header: {
                        HStack {
                            Text(section.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choose Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}
