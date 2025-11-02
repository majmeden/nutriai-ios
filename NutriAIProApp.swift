import SwiftUI

struct Food: Identifiable, Codable {
    let id = UUID()
    var name: String
    var grams: Double
    var cal: Int
    var prot: Int
    var fat: Int
    var carb: Int
}

@Observable class Tracker: Codable {
    var daily: [Food] = []
    var history: [Date: [Food]] = [:]
    
    func add(_ food: Food) { daily.append(food) }
    
    func saveDay() {
        let today = Calendar.current.startOfDay(for: Date())
        history[today] = daily
        daily = []
        save()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "nutriai"),
           let decoded = try? JSONDecoder().decode(Tracker.self, from: data) {
            self.daily = decoded.daily
            self.history = decoded.history
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "nutriai")
        }
    }
}

struct ContentView: View {
    @State private var tracker = Tracker()
    @State private var showQuickAdd = false
    @State private var name = "", cal = "", prot = "", fat = "", carb = "", grams = "100"
    
    var total: (cal: Int, prot: Int, fat: Int, carb: Int) {
        let c = tracker.daily.reduce(0) { $0 + $1.cal }
        let p = tracker.daily.reduce(0) { $0 + $1.prot }
        let f = tracker.daily.reduce(0) { $0 + $1.fat }
        let b = tracker.daily.reduce(0) { $0 + $1.carb }
        return (c, p, f, b)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack {
                    Text("NutriAI Pro").font(.largeTitle).bold()
                    Text("2250 kcal • 180g P • 70g F • 225g C")
                        .font(.caption).foregroundStyle(.secondary)
                }
                
                if showQuickAdd {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Food name", text: $name)
                        HStack {
                            TextField("kcal", text: $cal).keyboardType(.numberPad)
                            TextField("P", text: $prot).keyboardType(.numberPad)
                            TextField("F", text: $fat).keyboardType(.numberPad)
                            TextField("C", text: $carb).keyboardType(.numberPad)
                        }
                        TextField("Grams", text: $grams).keyboardType(.numberPad)
                        Button("Add Food") {
                            if let c = Int(cal), let p = Int(prot), let f = Int(fat), let b = Int(carb), let g = Double(grams) {
                                tracker.add(Food(name: name.isEmpty ? "Food" : name, grams: g, cal: c, prot: p, fat: f, carb: b))
                                name = ""; cal = ""; prot = ""; fat = ""; carb = ""; grams = "100"
                                showQuickAdd = false
                            }
                        }.buttonStyle(.borderedProminent)
                    }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    Button("Quick Add Food") { showQuickAdd = true }
                        .buttonStyle(.borderedProminent)
                }
                
                List {
                    ForEach(tracker.daily) { food in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(food.name).bold()
                                Text("\(Int(food.grams))g")
                            }
                            Spacer()
                            Text("\(food.cal)k | P\(food.prot) F\(food.fat) C\(food.carb)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.frame(height: 200)
                
                HStack(spacing: 20) {
                    VStack { Text("\(total.cal)").font(.title2).bold(); Text("kcal").font(.caption) }
                    VStack { Text("\(total.prot)g").font(.title2).bold(); Text("P").font(.caption) }
                    VStack { Text("\(total.fat)g").font(.title2).bold(); Text("F").font(.caption) }
                    VStack { Text("\(total.carb)g").font(.title2).bold(); Text("C").font(.caption) }
                }
                
                HStack {
                    Button("Save Day") { tracker.saveDay() }.buttonStyle(.bordered)
                    Button("Export") {
                        let txt = """
                        === NUTRIAI LOG ===
                        Calories: \(total.cal) / 2250
                        Protein: \(total.prot)g / 180g
                        Fat: \(total.fat)g / 70g
                        Carbs: \(total.carb)g / 225g
                        
                        Foods:
                        \(tracker.daily.map { "• \($0.name) \($0.grams)g → \($0.cal)kcal" }.joined(separator: "\n"))
                        """
                        UIPasteboard.general.string = txt
                    }.buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .onAppear { tracker.load() }
        }
    }
}

@main
struct NutriAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}