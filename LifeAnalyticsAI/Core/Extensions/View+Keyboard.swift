// MARK: - Core.Extensions

import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    func keyboardDismissOnTap() -> some View {
        modifier(KeyboardDismissOnTapModifier())
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct KeyboardDismissOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
    }
}
#else
extension View {
    func keyboardDismissOnTap() -> some View { self }
    func dismissKeyboard() {}
}
#endif
