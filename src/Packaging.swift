func packageApp(appPath: String, deviceIdentifier: String?, outputPath: String?, packageLauncherPath: String?, fileManager: NSFileManager) {
    let sourcePath = appPath
        |> getFullPath
        >>= validateFileExistence(fileManager: fileManager)
    
    // TODO: Result<T,E> would be better for error handling.
    switch (isRequiredXcodeIsInstalled(), sourcePath) {
    case (false, _):
        print("You need to have \(RequiredXcodeVersion) installed and selected via xcode-select.")
    case (_, .None):
        print("Provided .app not found at \(appPath)")
    case (true, .Some(let sourcePath)):
        
        var targetPath: String
        switch outputPath {
        case .Some(let value): targetPath = value
        case .None: targetPath = defaultTargetPathForApp(sourcePath)
        }
        
        var launcherPath: String
        switch packageLauncherPath {
        case .Some(let value): launcherPath = value
        case .None: launcherPath = "/usr/local/share/app-package-launcher"
        }
        
        let productFolder = "\(launcherPath)/build"
        let productPath = "\(productFolder)/Release/app-package-launcher.app"
        let packagedAppFlag = "\"PACKAGED_APP=\(sourcePath)\""
        let targetDeviceFlag = targetDeviceFlagForDeviceIdentifier(deviceIdentifier)
        
        let exitCode =
        system("xcodebuild -project \(launcherPath)/app-package-launcher.xcodeproj \(packagedAppFlag) \(targetDeviceFlag) > /dev/null")
        
        switch exitCode {

        case 0:
            print("\(appPath) successfully packaged to \(targetPath)")
            do {
                try fileManager.removeItemAtPath(targetPath)
            } catch _ {
            }
            do {
                try fileManager.moveItemAtPath(productPath, toPath: targetPath)
            } catch _ {
            }
            do {
                try fileManager.removeItemAtPath(productFolder)
            } catch _ {
            }
            
        default:
            print("An error occurred when packaging \(appPath)")
            
        }

    default:
        fatalError("How did we get here?")
    }
}

func getFullPath(path: String) -> String? {
    return URL(path)?.path
}

func validateFileExistence(fileManager fileManager: NSFileManager)(path: String) -> String? {
    return fileManager.fileExistsAtPath(path) ? path : nil
}

func lastPathComponent(url url: NSURL) -> String? {
    return url.lastPathComponent
}

func URL(path: String) -> NSURL? {
    return NSURL.fileURLWithPath(path)
}

func deletePathExtension(path: String) -> String? {
    return (path as NSString).stringByDeletingPathExtension
}

func defaultTargetPathForApp(appPath: String) -> String {
    let appName = appPath
        |> URL
        >>= lastPathComponent
        >=> deletePathExtension
    
    return "\(appName!) Installer.app" // TODO: Wrap this in a type because the force unwrap is evil.
}

func targetDeviceFlagForDeviceIdentifier(deviceIdentifier: String?) -> String {
    switch deviceIdentifier {
    case .Some(let deviceIdentifier): return "\"TARGET_DEVICE=\(deviceIdentifier)\""
    case .None: return ""
    }
}
