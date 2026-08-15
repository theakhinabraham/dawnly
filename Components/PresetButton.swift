import SwiftUI

struct PresetButton: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected
                    ? Color.accentColor
                    : Color.gray.opacity(0.15)
                )
                .foregroundStyle(
                    isSelected
                    ? .white
                    : .primary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 14)
                )
        }
    }
}
