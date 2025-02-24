//get the data from the links and put it into an array of at most thirty objects at a time

import Foundation
import WidgetKit

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ambrukaitis.TheMet.objects")!
  }
}


class TheMetStore: ObservableObject {
  @Published var objects: [Object] = []
  let service = TheMetService()
  let maxIndex: Int
  
  init(_ maxIndex: Int = 30) {
    self.maxIndex = maxIndex
  }

  func fetchObjects(for queryTerm: String) async throws {
    if let objectIDs = try await service.getObjectIDs(from: queryTerm) {
      for (index, objectID) in objectIDs.objectIDs.enumerated()
            where index < maxIndex {
        if let object = try await service.getObject(from: objectID) {
          await MainActor.run {
            objects.append(object)
          }
        }
      }
      writeObjects()
      WidgetCenter.shared.reloadTimelines(ofKind: "TheMetWidget")
    }
  }
  //writing objects to json for widget
  func writeObjects() {
    let archiveURL = FileManager.sharedContainerURL()
      .appendingPathComponent("objects.json")
    print(">>> \(archiveURL)")
    
    if let dataToSave = try? JSONEncoder().encode(objects) {
      do {
        try dataToSave.write(to: archiveURL)
      } catch {
        print("Error: Can't write objects")
      }
    }
  }
}
