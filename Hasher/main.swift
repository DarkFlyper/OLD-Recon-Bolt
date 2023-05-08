import Foundation

let toHash = "asdf"
print(toHash)

let hash = SaltedHash(salting: toHash)
print(hash)
print(hash.matches(bytesOf: toHash))
print(hash.matches(bytesOf: "oh no"))
