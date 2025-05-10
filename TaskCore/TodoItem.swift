//
//  TodoItem.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//


//import Foundation
//
//struct TodoItem: Identifiable, Codable, Equatable {
//    let id: UUID
//    var title: String
//    var isCompleted: Bool
//    
//    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
//        self.id = id
//        self.title = title
//        self.isCompleted = isCompleted
//    }
//    
//    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
//        lhs.id == rhs.id
//    }
//}

import Foundation
import CloudKit

struct TodoItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var recordID: CKRecord.ID? // For CloudKit syncing
    var modificationDate: Date? // Track when the item was last modified
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, recordID: CKRecord.ID? = nil, modificationDate: Date? = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.recordID = recordID
        self.modificationDate = modificationDate
    }
    
    // Convert TodoItem to CKRecord
    func toCKRecord() -> CKRecord {
        let recordID = self.recordID ?? CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "TodoItem", recordID: recordID)
        record["title"] = title as CKRecordValue
        record["isCompleted"] = isCompleted as CKRecordValue
        record["id"] = id.uuidString as CKRecordValue
        return record
    }
    
    // Create TodoItem from CKRecord
    static func fromCKRecord(_ record: CKRecord) -> TodoItem? {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let title = record["title"] as? String,
            let isCompleted = record["isCompleted"] as? Bool
        else {
            return nil
        }
        
        return TodoItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            recordID: record.recordID,
            modificationDate: record.modificationDate
        )
    }
    
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Implementation
extension TodoItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, recordIDName, zoneID, modificationDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate)
        
        // Handle CKRecord.ID decoding
        if let recordIDName = try container.decodeIfPresent(String.self, forKey: .recordIDName) {
            recordID = CKRecord.ID(recordName: recordIDName)
        } else {
            recordID = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(modificationDate, forKey: .modificationDate)
        
        // Handle CKRecord.ID encoding
        if let recordID = recordID {
            try container.encode(recordID.recordName, forKey: .recordIDName)
        }
    }
}
