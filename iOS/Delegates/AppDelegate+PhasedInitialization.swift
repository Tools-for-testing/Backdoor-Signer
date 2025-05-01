import UIKit

// MARK: - Phased Initialization Extension

extension AppDelegate {
    /// Set up components in phases for improved stability
    func setupPhaseOne() {
        Debug.shared.log(message: "Starting phase 1 initialization (lightweight components)", type: .info)

        // Initialize essential network monitoring
        setupNetworkMonitoring()

        // Validate server certificates for server functionality and offline signing
        _ = ServerCertificateManager.shared.validateCertificates()

        // Show startup popup if needed - low resource impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showAppropriateStartupScreen()
        }
    }

    /// Set up medium-weight components (phase 2)
    func setupPhaseTwo() {
        Debug.shared.log(message: "Starting phase 2 initialization (medium-weight components)", type: .info)

        // Initialize image pipeline (method name kept as in original codebase)
        imagePipline()

        // Set up essential background tasks
        setupBackgroundTasks()

        // Initialize terminal components
        setupTerminal()

        // Delay showing floating buttons to ensure UI hierarchy is fully established
        // Only show floating buttons if not showing startup popup and not in safe mode
        if !isShowingStartupPopup, !SafeModeLauncher.shared.inSafeMode {
            // Increased delay to ensure UI is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Verify app is still active and check UI state before showing buttons
                guard UIApplication.shared.applicationState == .active,
                      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      window.rootViewController != nil,
                      !self.isShowingStartupPopup else {
                    Debug.shared.log(message: "Skipping button initialization - UI not ready", type: .warning)
                    return
                }
                
                Debug.shared.log(message: "Initializing floating buttons with proper delay", type: .info)
                
                // Initialize floating button first
                FloatingButtonManager.shared.show()
                
                // Add another small delay before terminal button to stagger initialization
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Show terminal button if enabled - with additional UI check
                    if UserDefaults.standard.bool(forKey: "show_terminal_button") {
                        TerminalButtonManager.shared.show()
                    }
                }
            }
        }
    }

    /// Set up heavy components (phase 3) with safeguards
    func setupPhaseThree() {
        Debug.shared.log(message: "Starting phase 3 initialization (heavy-weight components)", type: .info)

        // Skip in safe mode
        if SafeModeLauncher.shared.inSafeMode {
            Debug.shared.log(message: "Skipping heavy component initialization in safe mode", type: .info)
            return
        }

        // These operations are moved to background to avoid blocking app launch
        backgroundQueue.async { [weak self] in
            // Store AI settings in local variables to avoid redundant checks
            let aiLearningEnabled = UserDefaults.standard.bool(forKey: "AILearningEnabled")
            let aiPromptShown = UserDefaults.standard.bool(forKey: "AIPromptShown")

            // Check if user has opted in to AI
            if aiLearningEnabled {
                // Initialize AI in background thread with delay to ensure UI stability
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.initializeAILearning()
                }
            } else if !aiPromptShown {
                // First time - ask for user consent
                DispatchQueue.main.async { [weak self] in
                    self?.promptForAIInitializationSafely()
                }
            }

            // Setup AI integration if enabled (but only after a delay)
            if aiLearningEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    AppContextManager.shared.setupAIIntegration()
                }
            }
        }
    }

    /// Method with phased initialization for crash protection
    func initializeComponentsWithCrashProtection() {
        Debug.shared.log(message: "Initializing components with crash protection", type: .info)

        // Use structured error handling to prevent crashes during initialization
        // Phase 1 - safe to run immediately
        setupPhaseOne()
        
        // Phase 2 - defer slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Execute Phase 2 setup
            self.setupPhaseTwo()
        }
        
        // Phase 3 - defer significantly and only if memory allows
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            
            // Check memory before heavy operations
            if self.shouldProceedWithMemoryCheck() {
                // Execute Phase 3 setup
                self.setupPhaseThree()
            } else {
                Debug.shared.log(message: "Skipping Phase 3 due to high memory usage", type: .warning)
            }
        }
        
        // Post initialization complete notification after all phases
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            NotificationCenter.default.post(name: .appInitializationCompleted, object: nil)
            Debug.shared.log(message: "App initialization complete", type: .success)
        }
        
        // Ensure UI is responsive regardless of initialization state
        DispatchQueue.main.async {
            // Use UIWindowScene.windows on iOS 15+ instead of deprecated UIApplication.shared.windows
            if #available(iOS 15.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.view.isUserInteractionEnabled = true
                }
            } else {
                // Fallback for older iOS versions
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    rootVC.view.isUserInteractionEnabled = true
                }
            }
        }
    }

    /// Check available memory before heavy operations
    func shouldProceedWithMemoryCheck() -> Bool {
        let memoryUsed = getMemoryUsage()
        Debug.shared.log(message: "Current memory usage: \(String(format: "%.1f%%", memoryUsed * 100))", type: .info)

        // If memory usage is over 70%, delay heavy operations
        return memoryUsed < 0.7
    }

    /// Get current memory usage as a percentage (0.0 to 1.0)
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            return usedMemory / totalMemory
        }

        return 0.0
    }
}
