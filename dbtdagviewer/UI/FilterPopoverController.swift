import AppKit

@MainActor
final class FilterPopoverController: NSViewController {

    private var filter: NodeFilter
    private let onChange: (NodeFilter) -> Void
    private let onReset: () -> Void

    private var orphanCheckbox: NSButton?

    init(
        filter: NodeFilter,
        onChange: @escaping (NodeFilter) -> Void,
        onReset: @escaping () -> Void
    ) {
        self.filter = filter
        self.onChange = onChange
        self.onReset = onReset
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func loadView() {
        let outer = NSView()
        outer.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(sectionHeader("Show"))
        stack.addArrangedSubview(typeCheckbox(title: "Sources", key: "sources", on: filter.showSources))
        stack.addArrangedSubview(orphanRow(on: filter.showOrphanSources, enabled: filter.showSources))
        stack.addArrangedSubview(typeCheckbox(title: "Seeds", key: "seeds", on: filter.showSeeds))
        stack.addArrangedSubview(typeCheckbox(title: "Tests", key: "tests", on: filter.showTests))
        stack.addArrangedSubview(typeCheckbox(title: "Exposures", key: "exposures", on: filter.showExposures))

        stack.addArrangedSubview(separator())

        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(handleReset))
        resetButton.bezelStyle = .rounded
        resetButton.controlSize = .small
        stack.addArrangedSubview(resetButton)

        outer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
            stack.topAnchor.constraint(equalTo: outer.topAnchor),
            stack.bottomAnchor.constraint(equalTo: outer.bottomAnchor),
        ])

        self.view = outer
        preferredContentSize = NSSize(width: 220, height: 0)
    }

    private func sectionHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func separator() -> NSView {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return box
    }

    private func typeCheckbox(title: String, key: String, on: Bool) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: self, action: #selector(typeChanged(_:)))
        button.state = on ? .on : .off
        button.identifier = NSUserInterfaceItemIdentifier(key)
        return button
    }

    private func orphanRow(on: Bool, enabled: Bool) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 0
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 22, bottom: 0, right: 0)
        let button = NSButton(checkboxWithTitle: "Include orphan sources", target: self, action: #selector(orphanChanged(_:)))
        button.state = on ? .on : .off
        button.isEnabled = enabled
        orphanCheckbox = button
        stack.addArrangedSubview(button)
        return stack
    }

    @objc private func typeChanged(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        switch key {
        case "sources":
            filter.showSources = sender.state == .on
            orphanCheckbox?.isEnabled = filter.showSources
        case "seeds":
            filter.showSeeds = sender.state == .on
        case "tests":
            filter.showTests = sender.state == .on
        case "exposures":
            filter.showExposures = sender.state == .on
        default: break
        }
        onChange(filter)
    }

    @objc private func orphanChanged(_ sender: NSButton) {
        filter.showOrphanSources = sender.state == .on
        onChange(filter)
    }

    @objc private func handleReset() {
        onReset()
    }
}
