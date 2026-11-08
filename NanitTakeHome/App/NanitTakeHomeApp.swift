//
//  NanitTakeHomeApp.swift
//  Nanit TakeHome
//
//  Created by Daniel Rodriguez on 11/7/26.
//

import SwiftUI

/// The SwiftUI App entry point
///
/// The Details model is created here for two reasons (rather than with its view), first for lifetime
/// to enture that it is created only once.  The second reason is that previews and tests can hand it a
/// different one, for example with a filled profile.
///
@main
struct Nanit_TakeHomeApp: App {
    
    /// Using `@State` here ensures that it lives as long as the `App` process, so the
    /// model is created exactly once.
    @State private var detailsModel = DetailsModel()
    
    var body: some Scene {
        WindowGroup {
            DetailsView(model: detailsModel)
        }
    }
}
