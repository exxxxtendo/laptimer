import SwiftUI

struct RecordsListView: View {
    @EnvironmentObject var recordsStore: RecordsStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(recordsStore.records.keys), id: \.self) { trackName in
                    HStack {
                        Text(trackName)
                            .font(.headline)
                        Spacer()
                        if let time = recordsStore.records[trackName] {
                            Text(Fmt.lap(time))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Records")
            .toolbar {
                Button("Закрыть") { dismiss() }
            }
        }
    }
}
