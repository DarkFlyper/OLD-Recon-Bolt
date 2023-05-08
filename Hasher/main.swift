import Foundation
import ValorantAPI

let id = Player.ID()
let toHash = id.rawID.description
print(toHash)

print(Denylist.allows(id))

let hash = SaltedHash(salting: toHash)
print(hash)
print(hash.matches(bytesOf: toHash))
print(hash.matches(bytesOf: "oh no"))
