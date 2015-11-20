func printDevices() {
    supportedInstrumentsConfigurations()
        |> filterLinesContainingSimulator
        |> map(truncateUuid)
        |> sorted { $0 > $1 }
        |> map(printIt)
}

func supportedInstrumentsConfigurations() -> [String] {
    return run("xcrun instruments -s")
}

func filterLinesContainingSimulator(lines: [String]) -> [String] {
    return lines |> filteredWithPredicate {
        string in
        return string.rangeOfString("Simulator") != nil
    }
}

func truncateUuid(string: String) -> String {
    let index = string.endIndex.advancedBy(-38)
    return string.substringToIndex(index)
}

func printIt(string: String) {
    print(string)
}
