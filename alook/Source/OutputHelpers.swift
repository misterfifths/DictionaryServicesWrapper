// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation

struct FileHandleOutputStream: TextOutputStream {
    let fileHandle: FileHandle

    public init(_ fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return // encoding failure
        }

        fileHandle.write(data)
    }
}

var stderr = FileHandleOutputStream(FileHandle.standardError)
var stdout = FileHandleOutputStream(FileHandle.standardOutput)


func warn(_ message: String) {
    print("\(message.yellow)", to: &stderr)
}

func info(_ message: String) {
    print("\(message.green.faint)", to: &stderr)
}

func die(_ message: String, details: String? = nil, exitCode: Int32 = 1) -> Never {
    print("\(message.red)", to: &stderr)
    if let details = details {
        print(details, to: &stderr)
    }

    exit(exitCode)
}

enum TaskFailureMode {
    case ignore
    case warn
    case die
}

func task(_ message: String, failureMode: TaskFailureMode = .die, block: () throws -> ()) {
    print("\(message.blue.bold)... ", terminator: "")

    do {
        try block()
        print("👍")
    }
    catch {
        switch failureMode {
        case .die:
            print("💀")
            die(error.localizedDescription)

        case .warn:
            print("⚠️")
            warn(error.localizedDescription)

        case .ignore:
            print("👍")
        }
    }

    print("")
}
