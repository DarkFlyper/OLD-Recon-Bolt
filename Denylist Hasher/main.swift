import Foundation

let toHash = "asdf"

let hash = SaltedHash(salting: toHash)
print(hash)
print(hash.matches(bytesOf: toHash))
print(hash.matches(bytesOf: "oh no"))
