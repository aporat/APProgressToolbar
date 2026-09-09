# APProgressToolbar

A Swift package providing a customizable toolbar with a progress bar, title, and cancel button for iOS. Easily integrate progress tracking into your app’s UI with animated show/hide functionality.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faporat%2FAAPProgressToolbar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/aporat/APProgressToolbar)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faporat%2FAPProgressToolbar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/aporat/APProgressToolbar)
![GitHub Actions Workflow Status](https://github.com/aporat/APProgressToolbar/actions/workflows/ci.yml/badge.svg)


## Installation

### Swift Package Manager
Add `APProgressToolbar` to your project via Swift Package Manager:

1. In Xcode, go to `File > Add Package Dependency`.
2. Enter the repository URL:
   ```
   https://github.com/aporat/APProgressToolbar.git
   ```
3. Specify the version or branch (e.g., `main`) and add it to your target.

Or, manually add it to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/aporat/APProgressToolbar.git", from: "1.0.0")
]
```
Then include it in your target:
```swift
.target(name: "YourTarget", dependencies: ["APProgressToolbar"])
```

## Usage

The toolbar positions itself at the bottom of its superview. Add it once, then drive it with
`show(_:)` / `hide(_:)`, `text`, and `progressBar.progress`.

```swift
final class HomeController: UIViewController {

    private lazy var loadingToolbar: APProgressToolbar = {
        let view = APProgressToolbar()
        view.isHidden = true
        view.cardBackgroundColor = .systemBackground
        view.titleColor = .label
        view.progressColors = [.systemBlue, .systemTeal]
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadingToolbar.actionDelegate = self
        view.addSubview(loadingToolbar)
        loadingToolbar.updateLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.loadingToolbar.updateLayout()
        }
    }

    func startLoading() {
        loadingToolbar.text = NSLocalizedString("Loading...", comment: "")
        loadingToolbar.progressBar.progress = 0
        Task { await loadingToolbar.show(true) }
    }

    func finishLoading() {
        loadingToolbar.progressBar.progress = 1
        Task { await loadingToolbar.hide(true) }   // waits a moment, then slides out
    }
}

extension HomeController: APProgressToolbarDelegate {
    func didCancelButtonPressed(_ toolbar: APProgressToolbar) {
        // stop the work
    }
}
```

Set `extraBottomOffset` to keep the card above content pinned to the bottom, such as an ad banner.
