import Foundation

struct GoogleClassroomCourse {
    let id: String
    let name: String
}

struct GoogleClassroomCoursework {
    let id: String
    let courseId: String
    let title: String
    let dueDate: Date?
}

final class GoogleClassroomService {
    static let shared = GoogleClassroomService()
    private init() {}
    
    func fetchCourses(completion: @escaping ([GoogleClassroomCourse]) -> Void) {
        completion([])
    }
    
    func fetchCoursework(completion: @escaping ([GoogleClassroomCoursework]) -> Void) {
        completion([])
    }
    
    func markCourseworkDone(courseworkId: String, courseId: String, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}
