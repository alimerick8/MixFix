//
//  CustomStudyBlockSD.swift
//  MixFix
//
//  Custom study blocks created by user
//

import Foundation
import SwiftData

@Model
final class CustomStudyBlockSD {
    var id: UUID
    var title: String
    var className: String?
    var workType: String?
    var startTime: Date
    var duration: Int
    var userId: String
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, className: String? = nil, workType: String? = nil, startTime: Date, duration: Int, userId: String) {
        self.id = id
        self.title = title
        self.className = className
        self.workType = workType
        self.startTime = startTime
        self.duration = duration
        self.userId = userId
        self.createdAt = Date()
    }
}
