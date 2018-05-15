// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import Darwin.C

private func stdoutSupportsColor() -> Bool {
    if isatty(FileHandle.standardOutput.fileDescriptor) == 0 {
        return false
    }

    let environment = ProcessInfo.processInfo.environment

    if let term = environment["TERM"] {
        if term == "dumb" {
            return false
        }
    }

    if let xpcServiceName = environment["XPC_SERVICE_NAME"] {
        if xpcServiceName.hasPrefix("com.apple.dt.Xcode") {
            // attempt to detect running inside Xcode...
            return false
        }
    }

    return true
}

fileprivate protocol ANSIWrapper {
    var startString: String { get }
    var endString: String { get }
}

fileprivate enum ANSITextColor : UInt, ANSIWrapper {
    case red = 31
    case green = 32
    case yellow = 33
    case blue = 34
    case gray = 37

    var startString: String {
        return "\u{1b}[\(self.rawValue)m"
    }

    var endString: String {
        return "\u{1b}[39m"
    }
}

fileprivate enum ANSITextWeight : UInt, ANSIWrapper {
    case bold = 1
    case faint = 2

    var startString: String {
        return "\u{1b}[\(self.rawValue)m"
    }

    var endString: String {
        return "\u{1b}[22m"
    }
}

extension String {
    fileprivate static let useColor = stdoutSupportsColor()

    fileprivate func withWrapper(_ wrapper: ANSIWrapper) -> String {
        if String.useColor {
            return "\(wrapper.startString)\(self)\(wrapper.endString)"
        }
        
        return self
    }

    var red: String { return withWrapper(ANSITextColor.red) }
    var green: String { return withWrapper(ANSITextColor.green) }
    var yellow: String { return withWrapper(ANSITextColor.yellow) }
    var blue: String { return withWrapper(ANSITextColor.blue) }
    var gray: String { return withWrapper(ANSITextColor.gray) }

    var bold: String { return withWrapper(ANSITextWeight.bold) }
    var faint: String { return withWrapper(ANSITextWeight.faint) }
}
