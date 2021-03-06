//
//  RegistrationViewModel.swift
//
//
//  Created by Valentin Knabel on 10.05.20.
//

import Combine
import ComposableArchitecture
import Foundation
import PufferyKit

public struct RegistrationState: Equatable {
    public var email = ""
    public var activity = ActivityState.idle

    public var shouldCheckEmails = false
    public var showsWelcomePage = false
    
    public init() {}

    public enum ActivityState: Equatable {
        case idle
        case inProgress
        case failed(FetchingError)

        public var inProgress: Bool {
            if case .inProgress = self {
                return true
            } else {
                return false
            }
        }

        public var failedError: FetchingError? {
            if case let .failed(error) = self {
                return error
            } else {
                return nil
            }
        }
    }
}

public enum RegistrationAction {
    case updateEmail(String)
    // TODO: remove onFinish
    case shouldRegister(onFinish: () -> Void)
    case shouldLogin(onFinish: () -> Void)

    case showCheckEmails(Bool)
    case showWelcomePage(Bool)

    case activityFinished
    case activityFailed(FetchingError)
}

public let registrationReducer = Reducer<
    RegistrationState,
    RegistrationAction,
    RegistrationEnvironment
> { (state, action, environment: RegistrationEnvironment) in
    switch action {
    case let .updateEmail(email):
        state.email = email
        return .none
    case let .showCheckEmails(shows):
        state.shouldCheckEmails = shows
        return .none
    case .showWelcomePage(false) where state.showsWelcomePage:
        state.showsWelcomePage = false
        return .init(value: .activityFinished)
    case let .showWelcomePage(shows):
        state.showsWelcomePage = shows
        return .none

    case .activityFinished:
        state.activity = .idle
        return .none
    case let .activityFailed(error):
        state.activity = .failed(error)
        return .none

    case let .shouldLogin(onFinish: onFinish):
        state.activity = .inProgress

        return environment.loginEffect(state.email)
            .handleEvents(receiveOutput: { onFinish() })
            .flatMap { _ in
                [
                    RegistrationAction.activityFinished,
                    RegistrationAction.showCheckEmails(true),
                ].publisher.transformError()
            }
            .catch { fetchingError in
                Effect<RegistrationAction, Never>(value: RegistrationAction.activityFailed(fetchingError))
            }
            .eraseToEffect()

    case .shouldRegister where state.activity.inProgress:
        return .none

    case let .shouldRegister(onFinish: onFinish):
        state.activity = .inProgress

        return environment.registerEffect(state.email.isEmpty ? nil : state.email)
            .handleEvents(receiveOutput: { _ in onFinish() })
            .transform(to: RegistrationAction.showWelcomePage(true))
            .catch { fetchingError in
                Effect<RegistrationAction, Never>(value: RegistrationAction.activityFailed(fetchingError))
            }
            .eraseToEffect()
    }
}
