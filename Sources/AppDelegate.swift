import AppKit
import SwiftUI
import Carbon
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var measurementOverlayWindows: [MeasurementOverlayWindow] = []
    private var eventMonitor: Any?
    private var hotkeyTap: CFMachPort?

    let measurementStore = MeasurementStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize CaliberState for shortcuts
        CaliberState.shared.configure(store: measurementStore)

        setupStatusItem()
        setupPopover()
        registerGlobalHotkey()
        setupEventMonitor()
        buildMenu()

        // Load subscription products and status
        if #available(macOS 13.0, *) {
            Task {
                await CaliberSubscriptionManager.shared.loadProducts()
                await CaliberSubscriptionManager.shared.updateStatus()
            }
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "ruler.fill", accessibilityDescription: "Caliber")
            button.image?.isTemplate = true
            button.toolTip = "Caliber — ⌘⇧M to measure"
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Measure (⌘⇧M)", action: #selector(startMeasurement), keyEquivalent: "m"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Caliber", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 200)
        popover.behavior = .transient
        popover.animates = true

        let contentView = ContentView(measurementStore: measurementStore, onMeasure: { [weak self] in
            self?.startMeasurement()
        }, onQuit: { [weak self] in
            self?.quitApp()
        })
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    // MARK: - Menu Bar

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Caliber", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Caliber", action: #selector(quitApp), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    // MARK: - Global Hotkey (⌘⇧M)

    private func registerGlobalHotkey() {
        // Command+Shift+M = keycode 0x2E (M key)
        let keyCode: CGKeyCode = 0x2E
        let modifiers: CGEventFlags = [.maskCommand, .maskShift]

        // Create run loop source for the tap
        var tapEventMask = (1 << CGEventType.keyDown.rawValue)
        let eventMask = CGEventMask(tapEventMask)

        // Use a class reference to avoid C callback issues
        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // Create the tap
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()

            guard type == .keyDown else { return Unmanaged.passRetained(event) }

            let sourceFlags = event.flags
            let hasCommand = sourceFlags.contains(.maskCommand)
            let hasShift = sourceFlags.contains(.maskShift)
            let hasM = event.keyCode == keyCode

            if hasCommand && hasShift && hasM {
                Task { @MainActor in
                    appDelegate.startMeasurement()
                }
            }

            return Unmanaged.passRetained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            // Fallback: NSEvent monitor (only works when app is frontmost)
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let hasCommand = flags.contains(.command)
                let hasShift = flags.contains(.shift)
                let hasM = event.keyCode == 0x2E

                if hasCommand && hasShift && hasM {
                    Task { @MainActor in
                        self?.startMeasurement()
                    }
                }
            }
            return
        }

        hotkeyTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    // MARK: - Event Monitor (Escape to cancel, click outside popover)

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.cancelMeasurement()
                return nil
            }
            return event
        }
    }

    // MARK: - Measurement

    @objc func startMeasurement() {
        closePopover()
        measurementStore.isMeasuring = true
        measurementStore.currentMeasurement = nil

        // Create overlay windows for all screens
        for screen in NSScreen.screens {
            let overlayWindow = MeasurementOverlayWindow(screen: screen, measurementStore: measurementStore)
            overlayWindow.orderFrontRegardless()
            measurementOverlayWindows.append(overlayWindow)
        }

        // Set crosshair cursor
        NSCursor.crosshair.set()
    }

    func cancelMeasurement() {
        measurementStore.isMeasuring = false
        measurementStore.currentMeasurement = nil
        closeOverlayWindows()
        NSCursor.arrow.set()
    }

    func finishMeasurement(width: CGFloat, height: CGFloat, screen: NSScreen) {
        measurementStore.isMeasuring = false
        closeOverlayWindows()
        NSCursor.arrow.set()

        let scaleFactor = screen.backingScaleFactor
        let widthPx = Int(width)
        let heightPx = Int(height)
        let widthPt = Int(width / scaleFactor)
        let heightPt = Int(height / scaleFactor)

        let measurement = Measurement(
            widthPx: widthPx,
            heightPx: heightPx,
            widthPt: widthPt,
            heightPt: heightPt,
            screenName: screen.localizedName
        )

        measurementStore.currentMeasurement = measurement
        measurementStore.lastMeasurement = measurement

        // Copy to clipboard: W×H format
        copyToClipboard(width: widthPx, height: heightPx)

        // VoiceOver announcement for accessibility
        announceMeasurement(width: widthPx, height: heightPx, screen: screen.localizedName)
    }

    private func closeOverlayWindows() {
        for window in measurementOverlayWindows {
            window.close()
        }
        measurementOverlayWindows.removeAll()
    }

    private func copyToClipboard(width: Int, height: Int) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("\(width)×\(height)", forType: .string)

        // Flash green on status item
        flashStatusItem()
    }

    private func flashStatusItem() {
        guard let button = statusItem.button else { return }
        let originalImage = button.image

        button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Copied")
        button.image?.isTemplate = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            button.image = originalImage
            button.image?.isTemplate = true
        }
    }

    private func announceMeasurement(width: Int, height: Int, screen: String) {
        let announcement = "Measurement complete: \(width) by \(height) pixels on \(screen)"
        let userInfo = [NSAccessibilityAnnouncementKey: announcement] as [String: Any]
        NSAccessibility.post(element: NSApp, notification: .announcement, userInfo: userInfo)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Global State for Shortcuts

@MainActor
final class CaliberState {
    static let shared = CaliberState()

    var store: MeasurementStore?

    private init() {}

    func configure(store: MeasurementStore) {
        self.store = store
    }

    func startMeasuring() {
        store?.isMeasuring = true
    }
}

