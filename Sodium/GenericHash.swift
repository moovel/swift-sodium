import Foundation
import Clibsodium

public class GenericHash {
    public let BytesMin = Int(crypto_generichash_bytes_min())
    public let BytesMax = Int(crypto_generichash_bytes_max())
    public let Bytes = Int(crypto_generichash_bytes())
    public let KeyBytesMin = Int(crypto_generichash_keybytes_min())
    public let KeyBytesMax = Int(crypto_generichash_keybytes_max())

    public let Primitive = String(validatingUTF8: crypto_generichash_primitive())

    /**
     Computes a fixed-length fingerprint for an arbitrary long message. A key can also be specified. A message will always have the same fingerprint for a given key, but different keys used to hash the same message are very likely to produce distinct fingerprints.

     - Parameter message: The message from which to compute the fingerprint.
     - Parameter key: Optional key to use while computing the fingerprint.

     - Returns: The computed fingerprint.
     */
    public func hash(message: Bytes, key: Bytes? = nil) -> Bytes? {
        return hash(message: message, key: key, outputLength: Bytes)
    }

    /**
     Computes a fixed-length fingerprint for an arbitrary long message. A message will always have the same fingerprint for a given key, but different keys used to hash the same message are very likely to produce distinct fingerprints.

     - Parameter message: The message from which to compute the fingerprint.
     - Parameter key: The key to use while computing the fingerprint.
     - Parameter outputLength: Desired length of the computed fingerprint.

     - Returns: The computed fingerprint.
     */
    public func hash(message: Bytes, key: Bytes?, outputLength: Int) -> Bytes? {
        var output = Array<UInt8>(count: outputLength)

        guard .SUCCESS == crypto_generichash(
            &output, outputLength,
            message, UInt64(message.count),
            key, key?.count ?? 0
        ).exitCode else { return nil }

        return output
    }

    /**
     Computes a fixed-length fingerprint for an arbitrary long message.

     - Parameter message: The message from which to compute the fingerprint.
     - Parameter outputLength: Desired length of the computed fingerprint.

     - Returns: The computed fingerprint.
     */
    public func hash(message: Bytes, outputLength: Int) -> Bytes? {
        return hash(message: message, key: nil, outputLength: outputLength)
    }

    /**
     Initializes a `Stream` object to compute a fixed-length fingerprint for an incoming stream of data.arbitrary long message. Particular data will always have the same fingerprint for a given key, but different keys used to hash the same data are very likely to produce distinct fingerprints.

     - Parameter key: Optional key to use while computing the fingerprint.

     - Returns: The initialized `Stream`.
     */
    public func initStream(key: Bytes? = nil) -> Stream? {
        return Stream(key: key, outputLength: Bytes)
    }

    /**
     Initializes a `Stream` object to compute a fixed-length fingerprint for an incoming stream of data.arbitrary long message. Particular data will always have the same fingerprint for a given key, but different keys used to hash the same data are very likely to produce distinct fingerprints.

     - Parameter key: Optional key to use while computing the fingerprint.
     - Parameter outputLength: Desired length of the computed fingerprint.

     - Returns: The initialized `Stream`.
     */
    public func initStream(key: Bytes?, outputLength: Int) -> Stream? {
        return Stream(key: key, outputLength: outputLength)
    }

    /**
     Initializes a `Stream` object to compute a fixed-length fingerprint for an incoming stream of data.arbitrary long message.

     - Parameter: outputLength: Desired length of the computed fingerprint.

     - Returns: The initialized `Stream`.
     */
    public func initStream(outputLength: Int) -> Stream? {
        return Stream(key: nil, outputLength: outputLength)
    }

    public class Stream: StateStream {
        typealias State = crypto_generichash_state
        static let capacity = crypto_generichash_statebytes()
        private var state: UnsafeMutablePointer<State>

        public var outputLength: Int = 0

        init?(key: Bytes?, outputLength: Int) {
            state = Stream.generate()

            guard .SUCCESS == crypto_generichash_init(
                state,
                key, key?.count ?? 0,
                outputLength
            ).exitCode else {
                free()
                return nil
            }

            self.outputLength = outputLength
        }

        private func free() {
            Stream.free(state)
        }

        deinit {
            free()
        }

        /**
         Updates the hash stream with incoming data to contribute to the computed fingerprint.

         - Parameter input: The incoming stream data.

         - Returns: `true` if the data was consumed successfully.
         */
        public func update(input: Bytes) -> Bool {
            return .SUCCESS == crypto_generichash_update(
                state,
                input, UInt64(input.count)
            ).exitCode
        }

        /**
         Signals that the incoming stream of data is complete and triggers computation of the resulting fingerprint.

         - Returns: The computed fingerprint.
         */
        public func final() -> Bytes? {
            let outputLen = outputLength
            var output = Array<UInt8>(count: outputLen)
            guard .SUCCESS == crypto_generichash_final(
                state,
                &output, outputLen
            ).exitCode else { return nil }

            return output
        }
    }
}

extension GenericHash: SecretKeyGenerator {
    public var KeyBytes: Int { return Int(crypto_generichash_keybytes()) }
    public typealias Key = Bytes

    static var keygen: (UnsafeMutablePointer<UInt8>) -> Void = crypto_generichash_keygen

}
