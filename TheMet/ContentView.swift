

import SwiftUI

struct ContentView: View {
  @StateObject private var store = TheMetStore()
  @State private var query = "rhino"
  @State private var showQueryField = false
  @State private var fetchObjectsTask: Task<Void, Error>?
  
  var body: some View {
    NavigationStack {
      VStack {
        Text("You searched for '\(query)'")
          .padding(5)
          .background(Color.metForeground)
          .cornerRadius(10)
        List(store.objects, id: \.objectID) { object in
          
          if !object.isPublicDomain,
             let url = URL(string: object.objectURL) {
            //opens safari view
            NavigationLink(value: url) {
              WebIndicatorView(title: object.title)
            }
            .listRowBackground(Color.metBackground)
            .foregroundColor(.white)
          } else {
            //loads in app
            NavigationLink(value: object) {
              Text(object.title)
            }
            .listRowBackground(Color.metForeground)
          }
        }
        
        .navigationTitle("The Met")
        //search button
        .toolbar {
          Button("Search the Met") {
            query = ""
            showQueryField = true
          }
          .foregroundColor(Color.metBackground)
          .padding(.horizontal)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.metBackground, lineWidth: 2))
        }
        .alert("Search the Met", isPresented: $showQueryField) {
          TextField("Search the Met", text: $query)
          Button("Search") {
            //if a fetch task is curently running, stop it
            fetchObjectsTask?.cancel()
            //get search objects
            fetchObjectsTask = Task {
              do {
                store.objects = []
                try await store.fetchObjects(for: query)
              } catch {}
            }
          }
        }
        //opens safari view if not public domain
        .navigationDestination(for: URL.self) { url in
          SafariView(url: url)
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea()
        }
        //opens object view if public domain
        .navigationDestination(for: Object.self) { object in
          ObjectView(object: object)
        }
      }
    }
    //fetches at the launch of app Only
    .task {
      do {
        try await store.fetchObjects(for: query)
      } catch {}
    }
    .overlay {
      if store.objects.isEmpty { ProgressView() }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

struct WebIndicatorView: View {
  let title: String
  
  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Image(systemName: "rectangle.portrait.and.arrow.right.fill")
        .font(.footnote)
    }
  }
}
