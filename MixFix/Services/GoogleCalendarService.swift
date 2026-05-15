import Foundation

struct GoogleCalendarEvent {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
}

final class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    private init() {}
    
    func fetchEvents(startDate: Date, endDate: Date, completion: @escaping ([GoogleCalendarEvent]) -> Void) {
        completion([])
    }
    
    func createEvent(fromStudyBlock title: String, startDate: Date, endDate: Date, completion: @escaping (String?) -> Void) {
        completion(nil)
    }
    
    func updateEvent(id: String, title: String, startDate: Date, endDate: Date, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
    
    func deleteEvent(id: String, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}
