import Foundation
import UIKit

// Extension to fix popup presentation issues
extension PopupViewController {
    /// Configures the sheet presentation controller to display the popup properly
    /// - Parameter hasUpdate: Whether the popup is displaying an update option
    func configureSheetPresentation(hasUpdate: Bool = false) {
        if let sheet = sheetPresentationController {
            // Using detents with appropriate heights
            if #available(iOS 16.0, *) {
                let smallDetent = UISheetPresentationController.Detent.custom { _ in
                    // Calculate based on number of buttons plus padding
                    hasUpdate ? 150.0 : self.calculateRequiredHeight()
                }
                sheet.detents = [smallDetent]
            } else {
                // Fallback for older iOS versions
                sheet.detents = [.medium()]
            }

            // Always show grabber for better UX
            sheet.prefersGrabberVisible = true

            // Set proper corner radius for consistent appearance
            sheet.preferredCornerRadius = 20.0
        }
    }

    /// Calculates the required height based on buttons content
    /// - Returns: Appropriate height for the popup sheet
    private func calculateRequiredHeight() -> CGFloat {
        // Base padding (top and bottom)
        let basePadding: CGFloat = 40.0

        // Use fixed button count since we can't access the private stackView
        let buttonCount = 2 // Default count, adjust if needed for your use case

        // Height per button plus spacing
        let buttonHeight: CGFloat = 50.0
        let buttonSpacing: CGFloat = 8.0 // Default spacing
        let spacingHeight: CGFloat = buttonSpacing * CGFloat(max(0, buttonCount - 1))

        // Calculate total required height
        return basePadding + (buttonHeight * CGFloat(buttonCount)) + spacingHeight
    }

    /// Enhanced button configuration with proper layout and spacing
    /// - Parameter buttons: Array of buttons to display in popup
    func configureButtonsWithLayout(_ buttons: [PopupViewControllerButton]) {
        // Use the public interface to configure buttons
        configureButtons(buttons)

        // Add bottom constraint to ensure proper sizing of the popup
        if let lastButton = buttons.last, lastButton.superview != nil {
            NSLayoutConstraint.activate([
                lastButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ])
        }
    }
}
