import ValorantAPI

struct PlayerHighlightInfo {
	private var highlightedPlayer: Player?
	
	func shouldFade(_ playerID: Player.ID) -> Bool {
		isHighlighting(playerID) == false
	}
	
	func shouldFade(_ partyID: Party.ID) -> Bool {
		isHighlighting(partyID) == false
	}
	
	func isHighlighting(_ playerID: Player.ID) -> Bool? {
		guard let highlightedPlayer else { return nil }
		return playerID == highlightedPlayer.id
	}
	
	func isHighlighting(_ partyID: Party.ID) -> Bool? {
		guard let highlightedPlayer else { return nil }
		return partyID == highlightedPlayer.partyID
	}
	
	mutating func switchHighlight(to player: Player) {
		// switch highlight to this player or toggle it off
		highlightedPlayer = highlightedPlayer?.id == player.id ? nil : player
	}
}
