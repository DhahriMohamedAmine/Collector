class SmartLight {
    var name: String
    var onUpdate: (() -> Void)?

    init(name: String) {
        self.name = name
    }

    func connect() {
        // We assign a closure to handle updates
        onUpdate = { [weak self] in
            guard  let self else {
                return
            }
            print("\(self.name) light is updating firmware...")
        }
    }

    deinit {
        print("💡 \(name) is being deallocated")
    }
}

// The Test:
var kitchenLight: SmartLight? = SmartLight(name: "Kitchen")
kitchenLight?.connect()
kitchenLight = nil