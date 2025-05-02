import Foundation

public struct ARFile {
    var name: String
    var modificationDate: Date
    var ownerId: Int
    var groupId: Int
    var mode: Int
    var size: Int
    var content: Data
}

func removePadding(_ paddedString: String) -> String {
    let data = paddedString.data(using: .utf8)!

    guard let firstNonSpaceIndex = data.firstIndex(of: UInt8(ascii: " ")) else {
        return paddedString
    }

    let actualData = data[..<firstNonSpaceIndex] as Data
    return String(data: actualData, encoding: .utf8)!
}

enum ARError: Error {
    case badArchive(String)
}

func getFileInfo(_ data: Data, _ offset: Int) throws -> ARFile {
    let sizeRange = offset + 48 ..< offset + 48 + 10
    let sizeString = String(data: data.subdata(in: sizeRange), encoding: .ascii) ?? "0"
    let size = Int(removePadding(sizeString))!
    if size < 1 {
        throw ARError.badArchive("Invalid size")
    }

    let nameRange = offset ..< offset + 16
    let nameString = String(data: data.subdata(in: nameRange), encoding: .ascii) ?? ""
    let name = removePadding(nameString)
    guard name != "" else {
        throw ARError.badArchive("Invalid name")
    }

    // Extract timestamp
    let modificationTimeRange = offset + 16 ..< offset + 16 + 12
    let modificationTimeString = String(data: data.subdata(in: modificationTimeRange), encoding: .ascii) ?? "0"
    let modificationTime = Double(removePadding(modificationTimeString))!

    // Extract owner and group IDs
    let ownerIdRange = offset + 28 ..< offset + 28 + 6
    let ownerIdString = String(data: data.subdata(in: ownerIdRange), encoding: .ascii) ?? "0"
    let ownerId = Int(removePadding(ownerIdString))!

    let groupIdRange = offset + 34 ..< offset + 34 + 6
    let groupIdString = String(data: data.subdata(in: groupIdRange), encoding: .ascii) ?? "0"
    let groupId = Int(removePadding(groupIdString))!

    // Extract mode
    let modeRange = offset + 40 ..< offset + 40 + 8
    let modeString = String(data: data.subdata(in: modeRange), encoding: .ascii) ?? "0"
    let mode = Int(removePadding(modeString))!

    // Extract content
    let contentRange = offset + 60 ..< offset + 60 + size
    let content = data.subdata(in: contentRange)

    return ARFile(
        name: name,
        modificationDate: NSDate(timeIntervalSince1970: modificationTime) as Date,
        ownerId: ownerId,
        groupId: groupId,
        mode: mode,
        size: size,
        content: content
    )
}

public func extractAR(_ rawData: Data) throws -> [ARFile] {
    // Explicitly type magicBytes as [UInt8] to match the headerBytes type
    let magicBytes: [UInt8] = [0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A]
    let headerData = rawData.subdata(in: 0 ..< 8)
    // Create a more explicit [UInt8] array conversion for unambiguous type checking
    let headerBytes = [UInt8](headerData)
    if headerBytes != magicBytes {
        throw ARError.badArchive("Invalid magic")
    }

    let data = rawData.subdata(in: 8 ..< rawData.endIndex)

    var offset = 0
    var files: [ARFile] = []
    while offset < data.count {
        let fileInfo = try getFileInfo(data, offset)
        files.append(fileInfo)
        offset += fileInfo.size + 60
        offset += offset % 2
    }
    return files
}
