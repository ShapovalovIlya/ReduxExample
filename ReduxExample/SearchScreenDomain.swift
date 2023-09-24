//
//  SearchScreenDomain.swift
//  ReduxExample
//
//  Created by Илья Шаповалов on 24.09.2023.
//

import Foundation
import Combine

enum DataLoadingStatus: Equatable {
    case none
    case loading
    case error(Error)
    
    static func == (lhs: DataLoadingStatus, rhs: DataLoadingStatus) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

struct Genre: Identifiable, Equatable {
    let id: UUID
}

struct SearchScreenDomain {
    //MARK: - State
    struct State: Equatable {
        var query: String
        var topGenres: [Genre]
        var allGenres: [Genre]
        var dataLoadingStatus: DataLoadingStatus
        
        init(
            query: String = .init(),
            topGenres: [Genre] = .init(),
            allGenres: [Genre] = .init(),
            dataLoadingStatus: DataLoadingStatus = .none
        ) {
            self.query = query
            self.topGenres = topGenres
            self.allGenres = allGenres
            self.dataLoadingStatus = dataLoadingStatus
        }
    }
    
    //MARK: - Action
    enum Action {
        case viewAppeared
        case didTypeQuery(String)
        case _getTopGenresRequest
        case _getTopGenresResponse(Result<[Genre], Error>)
    }
    
    //MARK: - Dependencies
    let getTopGenres: (String) -> AnyPublisher<[Genre], Error>
    let getAllGenres: (String) -> AnyPublisher<[Genre], Error>
    
    //MARK: - Reducer
    func reduce(
        _ state: inout State,
        with action: Action
    ) -> AnyPublisher<Action, Never> {
        switch action {
        case .viewAppeared:
            guard state.dataLoadingStatus != .loading else {
                break
            }
            
            state.dataLoadingStatus = .loading
            return Just(._getTopGenresRequest)
                .eraseToAnyPublisher()
            
        case ._getTopGenresRequest:
            return getTopGenres("url")
                .map(toSuccessAction(_:))
                .catch(toFailAction(_:))
                .eraseToAnyPublisher()
            
        case let ._getTopGenresResponse(.success(genres)):
            state.dataLoadingStatus = .none
            state.topGenres = genres
            
        case let ._getTopGenresResponse(.failure(error)):
            if !state.allGenres.isEmpty {
                break
            } else {
                state.dataLoadingStatus = .error(error)
            }
            
        case let .didTypeQuery(query):
            state.query = query
        }
        
        return Empty().eraseToAnyPublisher()
    }
    
    func toSuccessAction(_ genres: [Genre]) -> Action {
        ._getTopGenresResponse(.success(genres))
    }
    
    func toFailAction(_ error: Error) -> Just<Action> {
        Just(._getTopGenresResponse(.failure(error)))
    }
    
    static let live = Self(
        getTopGenres: { _ in Empty().eraseToAnyPublisher() },
        getAllGenres: { _ in Empty().eraseToAnyPublisher() }
    )
}

final class SearchStore: ObservableObject {
    @Published private(set) var state: SearchScreenDomain.State
    private let reducer: (inout SearchScreenDomain.State, SearchScreenDomain.Action) -> AnyPublisher<SearchScreenDomain.Action, Never>
    private var cancelable: Set<AnyCancellable> = .init()
    
    init(
        state: SearchScreenDomain.State,
        reducer: @escaping (inout SearchScreenDomain.State, SearchScreenDomain.Action) -> AnyPublisher<SearchScreenDomain.Action, Never>
    ) {
        self.state = state
        self.reducer = reducer
    }
    
    func send(_ action: SearchScreenDomain.Action) {
        reducer(&state, action)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send(_:))
            .store(in: &cancelable)
    }
}
