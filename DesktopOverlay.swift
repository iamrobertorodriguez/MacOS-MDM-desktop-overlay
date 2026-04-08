import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []
    var fileWatcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let imagePath = resolveImagePath()
        guard let imagePath = imagePath else {
            print("No index.* image found in ~/Documents/wallpaper/")
            NSApp.terminate(nil)
            return
        }

        showOverlay(imagePath: imagePath)
        watchForChanges()

        // React to screen configuration changes (connect/disconnect monitor)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func resolveImagePath() -> String? {
        let dir = NSString("~/Documents/wallpaper").expandingTildeInPath
        let fm = FileManager.default
        let supported = ["jpg", "jpeg", "png", "heic", "tiff", "bmp", "gif", "webp"]
        for ext in supported {
            let path = "\(dir)/index.\(ext)"
            if fm.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    func showOverlay(imagePath: String) {
        // Close existing windows
        windows.forEach { $0.close() }
        windows.removeAll()

        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("Failed to load image: \(imagePath)")
            return
        }

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )

            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.backgroundColor = .black

            let imageView = NSImageView(frame: window.contentView!.bounds)
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.imageAlignment = .alignCenter
            imageView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(imageView)

            window.orderFront(nil)
            windows.append(window)
            print("Overlay on: \(screen.localizedName) (\(Int(screen.frame.width))x\(Int(screen.frame.height)))")
        }
    }

    func watchForChanges() {
        let dir = NSString("~/Documents/wallpaper").expandingTildeInPath
        let fd = open(dir, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            print("Image change detected, refreshing...")
            if let path = self?.resolveImagePath() {
                self?.showOverlay(imagePath: path)
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileWatcher = source
    }

    @objc func screensChanged() {
        print("Screen configuration changed, refreshing...")
        if let path = resolveImagePath() {
            showOverlay(imagePath: path)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
