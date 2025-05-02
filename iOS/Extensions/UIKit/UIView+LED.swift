import ObjectiveC
import UIKit

/// Extension for adding LED lighting effects to UIView elements
extension UIView {
    // MARK: - Properties

    /// The LED gradient layer - stored as associated object
    private var ledGradientLayer: CAGradientLayer? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.ledGradientLayer) as? CAGradientLayer
        }
        set {
            objc_setAssociatedObject(
                self,
                AssociatedKeys.ledGradientLayer,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// Animation group for the LED effect
    private var ledAnimationGroup: CAAnimationGroup? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.ledAnimationGroup) as? CAAnimationGroup
        }
        set {
            objc_setAssociatedObject(
                self,
                AssociatedKeys.ledAnimationGroup,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - Public Methods

    /// Add a soft LED glow effect to the view
    /// - Parameters:
    ///   - color: The main color of the LED effect
    ///   - intensity: Glow intensity (0.0-1.0, default: 0.6)
    ///   - spread: How far the glow spreads (points, default: 10)
    ///   - animated: Whether the glow should pulsate (default: true)
    ///   - animationDuration: Duration of pulse animation if animated (default: 2.0)
    func addLEDEffect(
        color: UIColor,
        intensity: CGFloat = 0.6,
        spread: CGFloat = 10,
        animated: Bool = true,
        animationDuration: TimeInterval = 2.0
    ) {
        // Remove any existing LED effect
        removeLEDEffect()

        // Create the gradient layer for the LED effect
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds.insetBy(dx: -spread, dy: -spread)

        // Set up gradient colors with transparency for subtle glow
        let innerColor = color.withAlphaComponent(intensity)
        let outerColor = color.withAlphaComponent(0)

        gradientLayer.colors = [outerColor.cgColor, innerColor.cgColor, innerColor.cgColor, outerColor.cgColor]
        gradientLayer.locations = [0.0, 0.3, 0.7, 1.0]

        // Use a radial gradient for omnidirectional glow
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)

        // Make sure the layer is positioned below content
        if let index = layer.sublayers?.firstIndex(where: { $0 is CAGradientLayer }) {
            layer.insertSublayer(gradientLayer, at: UInt32(index))
        } else {
            layer.insertSublayer(gradientLayer, at: 0)
        }

        ledGradientLayer = gradientLayer

        // Position and update the layer
        updateLEDLayerPosition()

        // Add animation if needed
        if animated {
            addLEDAnimation(duration: animationDuration, intensity: intensity)
        }
    }

    /// Add a flowing LED effect that follows the outline of the view
    /// - Parameters:
    ///   - color: The main color of the LED effect
    ///   - intensity: Glow intensity (0.0-1.0, default: 0.8)
    ///   - width: Width of the flowing LED effect (default: 5)
    ///   - speed: Animation speed - lower is faster (default: 2.0)
    @objc func addFlowingLEDEffect(
        color: UIColor,
        intensity: CGFloat = 0.8,
        width: CGFloat = 5,
        speed: TimeInterval = 2.0
    ) {
        // Skip if view bounds are invalid or very small
        guard bounds.width > 10, bounds.height > 10, window != nil else {
            Debug.shared.log(message: "Skipping LED effect - invalid view dimensions or not in window", type: .warning)
            return
        }
        
        // Remove any existing LED effect
        removeLEDEffect()
        
        // Use main thread for UI updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.window != nil else { return }
            
            // Create the gradient layer with defensive bounds checking
            let gradientLayer = CAGradientLayer()
            let safeWidth = min(width, min(self.bounds.width, self.bounds.height) / 4)
            
            gradientLayer.frame = CGRect(
                x: -safeWidth,
                y: -safeWidth,
                width: self.bounds.width + safeWidth * 2,
                height: self.bounds.height + safeWidth * 2
            )

            // Use safer intensity value to prevent visual issues
            let safeIntensity = min(intensity, 0.6)
            
            // Create gradient of the LED effect going around the view
            gradientLayer.colors = [
                color.withAlphaComponent(0).cgColor,
                color.withAlphaComponent(safeIntensity).cgColor,
                color.withAlphaComponent(safeIntensity).cgColor,
                color.withAlphaComponent(0).cgColor,
            ]

            // Set initial position for animation
            gradientLayer.startPoint = CGPoint.zero
            gradientLayer.endPoint = CGPoint(x: 1, y: 0)

            // Create a mask to only show the border - with crash protection
            let maskLayer = CAShapeLayer()
            
            // Create mask paths with defensive bounds checking
            let outerRect = CGRect(
                x: safeWidth / 2,
                y: safeWidth / 2,
                width: self.bounds.width + safeWidth,
                height: self.bounds.height + safeWidth
            )
            
            // Calculate safe corner radius
            let safeCornerRadius = min(
                self.layer.cornerRadius + safeWidth / 2,
                min(outerRect.width, outerRect.height) / 2
            )
            
            let maskPath = UIBezierPath(
                roundedRect: outerRect,
                cornerRadius: safeCornerRadius
            )

            // Create inner path with safer values
            let innerRect = CGRect(
                x: safeWidth * 1.5,
                y: safeWidth * 1.5,
                width: max(1, self.bounds.width - safeWidth),
                height: max(1, self.bounds.height - safeWidth)
            )
            
            let innerPath = UIBezierPath(
                roundedRect: innerRect,
                cornerRadius: max(0, self.layer.cornerRadius)
            )
            
            // Only append inner path if it's valid
            if innerRect.width > 0 && innerRect.height > 0 {
                maskPath.append(innerPath.reversing())
            }

            maskLayer.path = maskPath.cgPath
            maskLayer.fillRule = .evenOdd

            gradientLayer.mask = maskLayer

            // Add the gradient layer
            self.layer.insertSublayer(gradientLayer, at: 0)
            self.ledGradientLayer = gradientLayer

            // Animate the LED flow with a slightly slower speed for better performance
            let safeSpeed = max(speed, 3.0) // Ensure minimum animation time for performance
            self.animateFlowingLED(speed: safeSpeed)
            
            Debug.shared.log(message: "Added flowing LED effect successfully", type: .debug)
        }
    }

    /// Remove any LED lighting effects from the view
    func removeLEDEffect() {
        ledGradientLayer?.removeFromSuperlayer()
        ledGradientLayer = nil
        // Simply set the animation group to nil - it doesn't have a removeAllAnimations method
        ledAnimationGroup = nil
    }

    // MARK: - Private Helper Methods

    /// Update LED layer position when frame changes
    private func updateLEDLayerPosition() {
        guard let ledLayer = ledGradientLayer else { return }

        if ledLayer.type == .radial {
            // For radial gradient, center it on the view
            ledLayer.position = CGPoint(
                x: bounds.midX - ledLayer.bounds.midX,
                y: bounds.midY - ledLayer.bounds.midY
            )
        } else {
            // For flowing LED, update the mask
            if let maskLayer = ledLayer.mask as? CAShapeLayer {
                let borderWidth = 5.0 // Same as default width

                let maskPath = UIBezierPath(
                    roundedRect: CGRect(
                        x: borderWidth / 2,
                        y: borderWidth / 2,
                        width: bounds.width + borderWidth,
                        height: bounds.height + borderWidth
                    ),
                    cornerRadius: layer.cornerRadius + borderWidth / 2
                )

                let innerPath = UIBezierPath(
                    roundedRect: CGRect(
                        x: borderWidth * 1.5,
                        y: borderWidth * 1.5,
                        width: bounds.width,
                        height: bounds.height
                    ),
                    cornerRadius: layer.cornerRadius
                )
                maskPath.append(innerPath.reversing())

                maskLayer.path = maskPath.cgPath
            }
        }
    }

    /// Add pulsating animation to the LED effect
    private func addLEDAnimation(duration: TimeInterval, intensity: CGFloat) {
        guard let ledLayer = ledGradientLayer else { return }

        // Create scale animation
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.95
        scaleAnimation.toValue = 1.05
        scaleAnimation.autoreverses = true

        // Create opacity animation for pulsing effect
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = intensity - 0.2
        opacityAnimation.toValue = intensity + 0.1
        opacityAnimation.autoreverses = true

        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = duration
        animationGroup.repeatCount = .infinity
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Save reference and add animation
        ledAnimationGroup = animationGroup
        ledLayer.add(animationGroup, forKey: "ledPulse")
    }

    /// Animate the flowing LED effect
    private func animateFlowingLED(speed: TimeInterval) {
        guard let ledLayer = ledGradientLayer else { return }

        // Create animation for flowing effect around the border
        let flowAnimation = CAKeyframeAnimation(keyPath: "position")

        // Create a path that follows the border
        let path = UIBezierPath()

        let width = ledLayer.frame.width
        let height = ledLayer.frame.height

        // Start at top-left and move clockwise
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: width, y: 0)) // Top edge
        path.addLine(to: CGPoint(x: width, y: height)) // Right edge
        path.addLine(to: CGPoint(x: 0, y: height)) // Bottom edge
        path.addLine(to: CGPoint.zero) // Left edge

        flowAnimation.path = path.cgPath
        flowAnimation.duration = speed
        flowAnimation.repeatCount = .infinity
        flowAnimation.calculationMode = .paced

        // Also rotate the gradient colors
        let startPointAnimation = CAKeyframeAnimation(keyPath: "startPoint")
        startPointAnimation.values = [
            CGPoint.zero,
            CGPoint(x: 1, y: 0),
            CGPoint(x: 1, y: 1),
            CGPoint(x: 0, y: 1),
            CGPoint.zero,
        ]
        startPointAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        startPointAnimation.duration = speed
        startPointAnimation.repeatCount = .infinity

        let endPointAnimation = CAKeyframeAnimation(keyPath: "endPoint")
        endPointAnimation.values = [
            CGPoint(x: 1, y: 0),
            CGPoint(x: 1, y: 1),
            CGPoint(x: 0, y: 1),
            CGPoint.zero,
            CGPoint(x: 1, y: 0),
        ]
        endPointAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        endPointAnimation.duration = speed
        endPointAnimation.repeatCount = .infinity

        // Group the animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [startPointAnimation, endPointAnimation]
        animationGroup.duration = speed
        animationGroup.repeatCount = .infinity

        // Save reference and add animation
        ledAnimationGroup = animationGroup
        ledLayer.add(animationGroup, forKey: "flowingLED")
    }

    // MARK: - Associated Objects Keys

    private enum AssociatedKeys {
        static var ledGradientLayer: UnsafeRawPointer = .init(bitPattern: "ledGradientLayer".hashValue)!
        static var ledAnimationGroup: UnsafeRawPointer = .init(bitPattern: "ledAnimationGroup".hashValue)!
    }
}

// Convenience method for applying LED effects to UIButton
extension UIButton {
    /// Add LED effect to button with appropriate settings
    /// - Parameter color: The color of the LED effect (default: tint color)
    func addButtonLEDEffect(color: UIColor? = nil) {
        let effectColor = color ?? tintColor ?? .systemBlue
        addLEDEffect(
            color: effectColor,
            intensity: 0.5,
            spread: 12,
            animated: true,
            animationDuration: 2.0
        )
    }

    /// Add flowing LED border to button
    /// - Parameter color: The color of the LED effect (default: tint color)
    func addButtonFlowingLEDEffect(color: UIColor? = nil) {
        let effectColor = color ?? tintColor ?? .systemBlue
        addFlowingLEDEffect(
            color: effectColor,
            intensity: 0.7,
            width: 3,
            speed: 3.0
        )
    }
}

// Convenience methods for applying LED effects to UITabBar
extension UITabBar {
    /// Add a flowing LED effect around the tab bar
    /// - Parameter color: The color of the effect (default: tint color)
    func addTabBarLEDEffect(color: UIColor? = nil) {
        let effectColor = color ?? tintColor ?? .systemBlue
        addFlowingLEDEffect(
            color: effectColor,
            intensity: 0.6,
            width: 2,
            speed: 4.0
        )
    }
}

// Convenience methods for table view cells
extension UITableViewCell {
    /// Add subtle LED effect to highlight important cells
    /// - Parameter color: The color of the LED effect
    func addCellLEDEffect(color: UIColor) {
        contentView.addLEDEffect(
            color: color,
            intensity: 0.3,
            spread: 15,
            animated: true,
            animationDuration: 3.0
        )
    }
}
