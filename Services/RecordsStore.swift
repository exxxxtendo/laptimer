import Foundation

class RecordsStore: ObservableObject {
    @Published var records: [String: TimeInterval] = [:]
    
    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("records.json")
    }
    
    init() { load() }
    
    func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) else { return }
        records = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    func addRecord(trackName: String, time: TimeInterval) {
        if let best = records[trackName] {
            if time < best {
                records[trackName] = time
                save()
            }
        } else {
            records[trackName] = time
            save()
        }
    }
}
