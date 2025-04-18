# APProgressToolbar

A Swift package providing a customizable toolbar with a progress bar, title, and cancel button for iOS. Easily integrate progress tracking into your app’s UI with animated show/hide functionality.

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faporat%2FAAPProgressToolbar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/aporat/APProgressToolbar)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Faporat%2FAPProgressToolbar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/aporat/APProgressToolbar)
![GitHub Actions Workflow Status](https://github.com/aporat/APProgressToolbar/actions/workflows/ci.yml/badge.svg)
[![codecov](https://codecov.io/github/aporat/APProgressToolbar/graph/badge.svg?token=OHF9AE0KMC)](https://codecov.io/github/aporat/APProgressToolbar)


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
```swift
class ViewController: UIViewController {

    lazy fileprivate var loadingToolbar: APProgressToolbar = {
        let view = APProgressToolbar()
        view.progressBar.barBorderColor = .black
        view.progressBar.barBackgroundColor = .black
        view.progressBar.barBorderWidth = 1
        view.progressBar.barFillColor = .white
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingToolbar.actionDelegate = self
        loadingToolbar.frame = CGRect(x: 0, y: view.bounds.size.height, width: view.bounds.size.width, height: 55)
        view.addSubview(loadingToolbar)
        
    }
    
    @IBAction func showToolbar(_ sender: Any) {
        loadingToolbar.show(true, completion: nil)
        loadingToolbar.text = NSLocalizedString("Loading...", comment: "")
        loadingToolbar.progressBar.progress = 0.5
    }
    
    @IBAction func hideToolbar(_ sender: Any) {
        loadingToolbar.hide(true, completion: nil)
    }
}

// MARK: - APProgressToolbarDelegate
extension ViewController: APProgressToolbarDelegate {
func didCancelButtonPressed(_ toolbar: APProgressToolbar) {

    }
}
```
