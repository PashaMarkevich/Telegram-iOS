import Foundation
import Postbox
import SwiftSignalKit
import MtProtoKit

public func fetchHttpResource(url: String) -> Signal<MediaResourceDataFetchResult, MediaResourceDataFetchError> {
    if let urlString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed), let url = URL(string: urlString) {
        let signal = MTHttpRequestOperation.data(forHttpUrl: url)!
        return Signal { subscriber in
            subscriber.putNext(.reset)
            let disposable = signal.start(next: { next in
                if let response = next as? MTHttpResponse {
                    let fetchResult: MediaResourceDataFetchResult = .dataPart(resourceOffset: 0, data: response.data, range: 0 ..< Int64(response.data.count), complete: true)
                    subscriber.putNext(fetchResult)
                    subscriber.putCompletion()
                } else {
                    subscriber.putError(.generic)
                }
            }, error: { _ in
                subscriber.putError(.generic)
            }, completed: {
            })
            
            return ActionDisposable {
                disposable?.dispose()
            }
        }
    } else {
        return .never()
    }
}

public func fetchCurrentDate(with url: URL?) -> Signal<Int32?, NoError> {
    guard let url = url,
          let signal = MTHttpRequestOperation.data(forHttpUrl: url)
    else { return .never() }

    return Signal { subscriber in
        let disposable = signal.start(next: { next in
            if let next = next as? MTHttpResponse,
               let data = next.data {
                let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let date = dict?["unixtime"] as? Int32
                subscriber.putNext(date)
            } else {
                subscriber.putNext(nil)
            }
            subscriber.putCompletion()
        }, error: { _ in
            subscriber.putNext(nil)
            subscriber.putCompletion()
        }, completed: {
            subscriber.putCompletion()
        })

        return ActionDisposable {
            disposable?.dispose()
        }
    }
}
