//
//  ContentView.swift
//  ReduxExample
//
//  Created by Илья Шаповалов on 24.09.2023.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: SearchStore
    
    var body: some View {
        VStack {
            switch store.state.dataLoadingStatus {
            case .none:
                InfoView(
                    query: store.state.query,
                    topGenres: store.state.topGenres,
                    allGenres: store.state.allGenres
                )
                
            case .loading:
                ProgressView()
                
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
        .padding()
        .onAppear {
            store.send(.viewAppeared)
        }
    }
}

struct InfoView: View {
    let query: String
    let topGenres: [Genre]
    let allGenres: [Genre]
    
    var body: some View {
        VStack {
            HStack {
                TextField("", text: .constant(query))
                Button("search") {
                    NavigationLink(destination: EmptyView()) {
                        Text("Search")
                    }
                }
            }
            HStack {
                ForEach(topGenres) { genre in
                    Text(genre.id.uuidString)
                        .onTapGesture {
                            NavigationLink {
                                EmptyView()
                            } label: {
                                Text("")
                            }

                        }
                }
            }
            VStack(content: {
                ForEach(allGenres) { genre in
                    Text(genre.id.uuidString)
                }
            })
        }
    }
}

#Preview {
    ContentView(
        store: SearchStore(
        state: SearchScreenDomain.State(),
        reducer: SearchScreenDomain.live.reduce(_:with:)
    )
    )
}
