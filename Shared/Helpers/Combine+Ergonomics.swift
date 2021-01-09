import Combine
import HandyOperators

extension Publisher {
	func also(do action: @escaping (Output) -> Void) -> Publishers.Map<Self, Output> {
		map { $0 <- { action($0) } }
	}
	
	func asResult() -> Publishers.Catch<Publishers.Map<Self, Result<Output, Failure>>, Just<Result<Output, Failure>>> {
		self
			.map { Result<Output, Failure>.success($0) }
			.catch { Just(Result.failure($0)) }
	}
	
	func sinkResult(
		onSuccess: @escaping (Output) -> Void,
		onFailure: @escaping (Failure) -> Void,
		always: (() -> Void)? = nil
	) -> AnyCancellable {
		sink(
			receiveCompletion: {
				always?()
				guard case .failure(let error) = $0 else { return }
				onFailure(error)
			},
			receiveValue: onSuccess
		)
	}
}

extension Publisher where Failure == Error {
	func check(_ check: @escaping (Output) throws -> Void) -> Publishers.TryMap<Self, Output> {
		tryMap { try $0 <- { try check($0) } }
	}
}
