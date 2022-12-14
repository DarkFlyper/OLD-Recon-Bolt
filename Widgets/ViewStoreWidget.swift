import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators
import CGeometry

struct ViewStoreWidget: Widget {
	let kind: String = "Widgets"
	
	var body: some WidgetConfiguration {
		IntentConfiguration(kind: kind, intent: ViewStoreIntent.self, provider: StoreEntryProvider()) { entry in
			StoreEntryView(entry: entry)
				.widgetURL(entry.link.makeURL())
		}
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
		.configurationDisplayName("Store")
		.description("Check your current Valorant storefront.")
	}
}

struct StoreEntryView: View {
	var entry: StoreEntry
	
	let opacities = [0.25, 0.3]
	
	@Environment(\.widgetFamily) private var widgetFamily
	
	var body: some View {
		switch entry.info {
		case .success(let info):
			storefrontContents(for: info)
				.foregroundColor(entry.configuration.accentColor.color)
		case .failure(let error):
			Text(error.localizedDescription)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding()
		}
	}
	
	@ViewBuilder
	func storefrontContents(for info: StorefrontInfo) -> some View {
		if widgetFamily == .systemSmall {
			VStack(spacing: 0) {
				if entry.configuration.showRefreshTime == 1 {
					nextRefreshLabel(target: info.nextRefresh)
						.padding(4)
						.frame(maxWidth: .infinity)
						.background {
							Rectangle().opacity(opacities.last!)
						}
				}
				
				storeGrid(for: info)
			}
		} else {
			let isLarge = widgetFamily == .systemLarge
			storeGrid(for: info)
				.overlay(alignment: isLarge ? .leading : .top) {
					if entry.configuration.showRefreshTime != 0 { // eww NSNumber
						ZStack {
							ForEach(0..<3) { _ in // harder soft light lmao, this just looks best
								nextRefreshLabel(target: info.nextRefresh)
									.blendMode(.softLight)
							}
						}
						.padding(3)
						.background{
							Capsule().fill(.regularMaterial)
							Capsule().strokeBorder(Color.white).opacity(0.1)
						}
						// rotate around the top, where it's attached to the edge (even when rotated)
						.fixedSize()
						.frame(width: 0, height: 0, alignment: .top)
						.rotationEffect(isLarge ? .degrees(-90) : .zero)
						.padding(4)
						.foregroundColor(.primary)
					}
				}
		}
	}
	
	@ViewBuilder
	func storeGrid(for info: StorefrontInfo) -> some View {
		let columnCount = widgetFamily == .systemMedium ? 2 : 1
		let isSmall = widgetFamily == .systemSmall
		
		FixedColumnGrid(columns: columnCount) {
			ForEach(info.skins.indexed(), id: \.index) { index, skin in
				VStack(spacing: 4) {
					if !isSmall {
						skin.icon?.resizable().aspectRatio(contentMode: .fit)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
					}
					
					Text(skin.name)
						.font(.caption2)
						.opacity(0.8)
						.fixedSize(horizontal: false, vertical: true)
						.frame(height: isSmall ? 10 : nil) // fake smaller height to ensure all cells stay the same size
						.lineLimit(isSmall ? 2 : 1)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(.vertical, isSmall ? 4 : 8)
				.padding(.horizontal, 8)
				.background {
					let row = index / columnCount
					let col = index % columnCount
					Rectangle()
						.opacity(opacities[(row + col) % opacities.count])
				}
			}
		}
	}
	
	func nextRefreshLabel(target: Date) -> some View {
		HStack(spacing: 4) {
			Image(systemName: "clock")
			
			if target > .now {
				Text("Refreshes at \(target, format: .dateTime.hour().minute())")
			} else {
				Text("Storefront outdated!")
					.foregroundColor(.red)
			}
		}
		.padding(.trailing, 2)
		.font(.caption.weight(.medium))
	}
}

struct FixedColumnGrid: Layout {
	var columns: Int
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		proposal.replacingUnspecifiedDimensions()
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let size = bounds.size / CGSize(
			width: CGFloat(columns),
			height: (CGFloat(subviews.count) / CGFloat(columns)).rounded(.up)
		)
		for (index, view) in subviews.enumerated() {
			let position = CGPoint(x: index % columns, y: index / columns)
			view.place(
				at: bounds.origin + CGVector(size * position),
				proposal: .init(size)
			)
		}
	}
}

struct ViewStoreWidget_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			let view = StoreEntryView(entry: .mocked(
				info: .success(.init(
					nextRefresh: .init(timeIntervalSinceNow: 12345),
					skins: [
						.init(name: "a long-ass testing name (yes)", icon: Image("Example Skin")),
						.init(name: "much longer skin name", icon: Image("Example Skin")),
						.init(name: "test", icon: Image("Example Skin")),
						.init(name: "BlastX Polymer KnifeTech Coated Knife", icon: Image("Example Skin")),
					]
				)),
				configuration: .init() <- {
					$0.accentColor = .unknown
				}
			))
			
			view.previewContext(WidgetPreviewContext(family: .systemSmall))
				.previewDisplayName("Small")
			view.previewContext(WidgetPreviewContext(family: .systemMedium))
				.previewDisplayName("Medium")
			view.previewContext(WidgetPreviewContext(family: .systemLarge))
				.previewDisplayName("Large")
			
			StoreEntryView(entry: .mocked(
				info: .failure(StoreEntryProvider.UpdateError.missingAccount)
			))
			.previewDisplayName("No Account")
			
			StoreEntryView(entry: .mocked(
				info: .failure(APIError.rateLimited(retryAfter: 5))
			))
			.previewDisplayName("Other Error")
		}
		.previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
