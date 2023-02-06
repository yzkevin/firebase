//
//  SwiftUISampleApp.swift
//  SwiftUISample
//
//  Created by Charlotte Liang on 1/31/23.
//

import SwiftUI
import FirebaseCore

@main
struct SwiftUISampleApp: App {
  init() {
    FirebaseApp.configure(withFirebaseKey: "QUl6YVN5QXdGbF9LcThwbURST2Z3eXNNZEZGZG53MmIyZnMyTF9zLDE6NDQ5NDUxMTA3MjY1Omlvczo2NDQyYTBhMDA1OTEzMzFjZTg4NTQwLGZpci1pb3MtYXBwLWV4dGVuc2lvbnMsZmlyLWlvcy1hcHAtZXh0ZW5zaW9ucy5hcHBzcG90LmNvbSxodHRwczovL2Zpci1pb3MtYXBwLWV4dGVuc2lvbnMuZmlyZWJhc2Vpby5jb20K com.google.firebase.extensions.dev")
    //FirebaseApp.configure()
    
//    FirebaseApp.configure(withName: "My non default app", firebaseKey: """
//      QUl6YVN5QXdGbF9LcThwbURST2Z3eXNNZEZGZG53MmIyZnMyTF9zLDE6NDQ5NDUx
//      MTA3MjY1Omlvczo2NDQyYTBhMDA1OTEzMzFjZTg4NTQwLGZpci1pb3MtYXBwLWV4
//      dGVuc2lvbnMsZmlyLWlvcy1hcHAtZXh0ZW5zaW9ucy5hcHBzcG90LmNvbSxodHRw
//      czovL2Zpci1pb3MtYXBwLWV4dGVuc2lvbnMuZmlyZWJhc2Vpby5jb20K com.google.firebase.extensions.dev
//""")

  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
