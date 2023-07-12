import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators
import CGeometry

struct ViewStoreWidget: Widget {
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: WidgetKind.viewStore.rawValue,
			intent: ViewStoreIntent.self,
			provider: StoreEntryProvider()
		) { entry in
			StoreEntryView(entry: entry)
				.reloadingOnTap(.viewStore)
		}
		.supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
		.configurationDisplayName(Text("Store", comment: "Store Widget: title"))
		.description(Text("Check your current Valorant storefront.", comment: "Store Widget: description"))
	}
}

struct StoreEntryView: TimelineEntryView {
	var entry: StoreEntryProvider.Entry
	
	@Environment(\.adjustedWidgetFamily) private var widgetFamily
	
	var isLarge: Bool { widgetFamily == .systemLarge }
	
	func contents(for info: StorefrontInfo) -> some View {
		if widgetFamily == .systemSmall {
			VStack(spacing: 0) {
				if entry.configuration.showRefreshTime != 0 {
					nextRefreshLabel(target: info.nextRefresh)
						.font(.caption)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 3)
				}
				
				StoreGrid(
					configuration: entry.configuration, info: info,
					spacing: 3, columnCount: 1, isCompact: true
				)
			}
			.padding(3)
		} else {
			StoreGrid(
				configuration: entry.configuration, info: info,
				spacing: 6, columnCount: isLarge ? 1 : 2, isCompact: false
			)
			.padding(6)
			.overlay(alignment: isLarge ? .leading : .top) {
				if entry.configuration.showRefreshTime != 0 { // eww NSNumber
					refreshLabelOverlay(for: info)
				}
			}
		}
	}
	
	func refreshLabelOverlay(for info: StorefrontInfo) -> some View {
		ZStack {
			ForEach(0..<3) { _ in // harder soft light lmao, this just looks best
				nextRefreshLabel(target: info.nextRefresh)
					.blendMode(.softLight)
			}
		}
		.font(.caption.weight(.medium))
		.padding(3)
		.background {
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
	
	func nextRefreshLabel(target: Date) -> some View {
		HStack(spacing: 4) {
			Image(systemName: "clock")
			
			if target > .now {
				Text("Refreshes at \(target, format: .dateTime.hour().minute())", comment: "Store Widget: next refresh time (hour & minute)")
			} else {
				Text("Storefront outdated!")
					.foregroundColor(.red)
			}
		}
		.padding(.trailing, 2)
	}
}

struct StoreGrid: View {
	let configuration: ViewStoreIntent
	let info: StorefrontInfo
	
	var spacing: CGFloat
	var columnCount: Int
	var isCompact: Bool
	
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		FixedColumnGrid(columns: columnCount) {
			ForEach(info.skins.indexed(), id: \.index) { index, skin in
				VStack(spacing: 0) {
					let isShowingIcon = configuration.shouldShowIcon && !isCompact
					if isShowingIcon {
						skin.icon?.resizable().aspectRatio(contentMode: .fit)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.padding(.vertical, 4)
					}
					
					if configuration.shouldShowLabel {
						let isUltraCompact = isCompact && configuration.showRefreshTime != 0
						Text(skin.name)
							.font(.caption2)
							.foregroundColor(skin.tierColor?.opaque(), adjustedFor: colorScheme)
							.fixedSize(horizontal: false, vertical: true)
							.frame(height: isCompact ? 10 : nil) // fake smaller height to ensure all cells stay the same size
							.lineLimit(isShowingIcon || isUltraCompact ? 1 : 2)
							.multilineTextAlignment(.center)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(.vertical, 4)
				.padding(.horizontal, 8)
				.background(alignment: .topTrailing) {
					if !isCompact {
						skin.tierIcon?
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 16)
							.padding(4)
					}
				}
				.background(skin.tierColor?.opaque().opacity(0.2))
				.mask(ContainerRelativeShape())
				.padding(spacing)
			}
		}
	}
}

extension ViewStoreIntent {
	var shouldShowIcon: Bool {
		displayMode != .textOnly
	}
	
	var shouldShowLabel: Bool {
		displayMode != .iconOnly
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
	static let tiers = Managers.assets.assets?.contentTiers.values.sorted(on: \.rank)
	static let skins: [StorefrontInfo.Skin] = [
		.init(
			name: "a long-ass testing name (yes)",
			icon: Image("Example Skin"),
			tierColor: tiers?[0].color,
			tierIcon: Managers.images.image(for: tiers?[0].displayIcon).map(Image.init(uiImage:))
		),
		.init(
			name: "much longer skin name",
			icon: Image("Example Skin"),
			tierColor: tiers?[2].color
		),
		.init(
			name: "test",
			icon: Image("Example Skin"),
			tierColor: tiers?[3].color
		),
		.init(
			name: "BlastX Polymer KnifeTech Coated Knife",
			icon: Image("Example Skin"),
			tierColor: tiers?[4].color
		),
	]
	
	static var previews: some View {
		Group {
			let view = StoreEntryView(entry: .mocked(
				value: .init(
					nextRefresh: .init(timeIntervalSinceNow: 12345),
					skins: Self.skins
				)
			))
			
			view.previewContext(WidgetPreviewContext(family: .systemSmall))
				.previewDisplayName("Small")
			view.previewContext(WidgetPreviewContext(family: .systemMedium))
				.previewDisplayName("Medium")
			view.previewContext(WidgetPreviewContext(family: .systemLarge))
				.previewDisplayName("Large")
		}
		.previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
