import UIKit

extension UIButton {
    /// Apply modern style to a button with customizable parameters
    ///
    /// - Parameters:
    ///   - color: The main color of the button
    ///   - cornerRadius: The corner radius of the button (default: 10)
    ///   - font: The font to use for the button title (default: .systemFont(ofSize: 16, weight: .medium))
    ///   - shadowEnabled: Whether to add a shadow to the button (default: true)
    func applyModernStyle(
        color: UIColor,
        cornerRadius: CGFloat = 10,
        font: UIFont = .systemFont(ofSize: 16, weight: .medium),
        shadowEnabled: Bool = true
    ) {
        // Set up background color
        backgroundColor = color

        // Set up text color based on background color brightness - use fileprivate extension method
        let isLightBg = (color as UIColor).isLight()
        setTitleColor(isLightBg ? .black : .white, for: .normal)
        setTitleColor(isLightBg ? .darkGray : .lightGray, for: .highlighted)

        // Set up font
        titleLabel?.font = font

        // Set up corner radius
        layer.cornerRadius = cornerRadius
        clipsToBounds = !shadowEnabled // Only clip if we don't have a shadow

        // Set up shadow if enabled
        if shadowEnabled {
            layer.shadowColor = color.withAlphaComponent(0.5).cgColor
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowRadius = 5
            layer.shadowOpacity = 0.3
            layer.masksToBounds = false
        }

        // Add transition animation for state changes
        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )

        // Add press animation
        addPressAnimation()
    }

    /// Adds a scale-down animation when button is pressed
    func addPressAnimation() {
        addTarget(self, action: #selector(buttonPressed), for: [.touchDown, .touchDragEnter])
        addTarget(
            self,
            action: #selector(buttonReleased),
            for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        )
    }

    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.layer.shadowOpacity = 0.2
        })

        // Add haptic feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    @objc private func buttonReleased() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            self.transform = CGAffineTransform.identity
            self.layer.shadowOpacity = 0.3
        })
    }

    /// Create a modern floating action button
    ///
    /// - Parameters:
    ///   - image: The image to display in the button
    ///   - color: The button's background color
    ///   - size: The size of the button (width and height)
    /// - Returns: A configured UIButton
    static func modernFloatingButton(
        image: UIImage?,
        color: UIColor,
        size: CGFloat = 56
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        button.backgroundColor = color
        // Use our fileprivate method to avoid conflicts
        let isLight = color.isLight()
        button.tintColor = isLight ? .black : .white
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = size / 2
        button.clipsToBounds = false

        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2

        // Add press animation
        button.addPressAnimation()

        return button
    }
}

// Helper extension to determine if a color is light or dark
// Use extension in same file instead of global to avoid redeclarations
private extension UIColor {
    /// Determine if the color is light or dark
    /// - Returns: True if the color is light, false if it's dark
    func isLight() -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate relative luminance
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        return luminance > 0.5
    }
}

// Example extension for gradient buttons
extension UIButton {
    /// Apply a gradient background to the button
    /// - Parameters:
    ///   - colors: Array of UIColors to use in the gradient
    ///   - direction: The direction of the gradient (horizontal or vertical)
    func applyGradient(colors: [UIColor], direction: GradientDirection = .horizontal) {
        // Remove any existing gradient
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }

        // Set gradient direction
        switch direction {
        case .horizontal:
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        case .vertical:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        case .diagonal:
            gradientLayer.startPoint = CGPoint.zero
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        }

        // Set corner radius to match button
        gradientLayer.cornerRadius = layer.cornerRadius

        // Insert the gradient below the button's content
        layer.insertSublayer(gradientLayer, at: 0)
    }

    /// Direction options for gradient
    enum GradientDirection {
        case horizontal
        case vertical
        case diagonal
    }
}

// Extension for pill-shaped buttons
extension UIButton {
    /// Convert the button to a modern pill shape
    /// - Parameter color: The button's background color
    func applyPillStyle(color: UIColor) {
        backgroundColor = color
        // Use our private isLight() method
        let isLightColor = color.isLight()
        setTitleColor(isLightColor ? .black : .white, for: .normal)

        // Make fully rounded
        layer.cornerRadius = frame.height / 2
        clipsToBounds = true

        // Add padding with iOS 15 compatibility
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            configuration = config
        } else {
            // Legacy approach for iOS < 15
            contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }

        // Set font
        titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)

        // Add press animation
        addPressAnimation()
    }
}
