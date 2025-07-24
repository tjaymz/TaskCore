//
//  TodoItem.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import Foundation
import CloudKit

struct TodoItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var recordID: CKRecord.ID? // For CloudKit syncing
    var modificationDate: Date? // Track when the item was last modified locally
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, recordID: CKRecord.ID? = nil, modificationDate: Date? = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.recordID = recordID
        self.modificationDate = modificationDate
    }
    
    // Convert TodoItem to CKRecord - FIXED to only use required fields
    func toCKRecord() -> CKRecord {
        // If we have a recordID, use it, otherwise create a new one
        let recordID = self.recordID ?? CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "TodoItem", recordID: recordID)
        
        // ONLY store these specific fields - no custom modificationDate
        record["title"] = title as CKRecordValue
        record["isCompleted"] = isCompleted as CKRecordValue
        record["id"] = id.uuidString as CKRecordValue
        
        // Let CloudKit handle modificationDate automatically
        print("Creating CKRecord: type=TodoItem, id=\(id.uuidString), fields: title, isCompleted, id")
        
        return record
    }
    
    // Create TodoItem from CKRecord - FIXED to use system modificationDate
    static func fromCKRecord(_ record: CKRecord) -> TodoItem? {
        // Validate record type
        guard record.recordType == "TodoItem" else {
            print("Record is not a TodoItem type: \(record.recordType)")
            return nil
        }
        
        // Print available fields for debugging
        print("Reading CKRecord: \(record.recordID.recordName), available fields: \(Array(record.allKeys()))")
        
        // Extract and validate required fields
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String else {
            print("Missing or invalid required fields in record")
            return nil
        }
        
        // Extract optional fields with default values
        let isCompleted = record["isCompleted"] as? Bool ?? false
        
        // Use CloudKit's system modificationDate (this is always sortable)
        let modificationDate = record.modificationDate
        
        // Create TodoItem with all data
        return TodoItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            recordID: record.recordID,
            modificationDate: modificationDate
        )
    }
    
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Implementation
extension TodoItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, recordIDName, modificationDate
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
