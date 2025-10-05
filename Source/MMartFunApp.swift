import SwiftUI
import AVFoundation
import Combine

// MARK: - App Settings & Persistence
enum AppLanguage: String {
    case vi, en
}

class Settings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "MMartFun_Lang") }
    }
    static let shared = Settings()
    private init() {
        if let raw = UserDefaults.standard.string(forKey: "MMartFun_Lang"), let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            language = .vi
        }
    }
}

// MARK: - Models
enum Operation: CaseIterable, Codable {
    case multiply, divide, both
}

struct Question: Identifiable, Codable {
    let id = UUID()
    let a: Int
    let b: Int
    let op: Operation
    var textLocalized: (AppLanguage) -> String = { _ in "" }
    var text(for lang: AppLanguage) -> String {
        switch op {
        case .multiply:
            return "\(a) × \(b) = ?"
        case .divide:
            return "\(a * b) ÷ \(a) = ?"
        case .both:
            return "\(a) × \(b) = ?"
        }
    }
    var answer: Int {
        switch op {
        case .multiply, .both: return a * b
        case .divide: return b
        }
    }
}

// MARK: - ViewModel
class GameViewModel: ObservableObject {
    @Published var operation: Operation = .both
    @Published var questions: [Question] = []
    @Published var currentIndex = 0
    @Published var correctSolo = 0
    @Published var isRunning = false
    @Published var elapsedSec = 0
    @Published var modeDuel = false
    @Published var p1Correct = 0
    @Published var p2Correct = 0
    @Published var winner: String? = nil
    @Published var showLangSelector = false
    
    private var timer: AnyCancellable?
    private var startDate = Date()
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        // show language selector if first launch
        if UserDefaults.standard.string(forKey: "MMartFun_Lang") == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showLangSelector = true
            }
        }
    }
    
    func generateQuestions(count: Int = 20) {
        questions = (0..<count).map { _ in
            let op = operation == .both ? [Operation.multiply, .divide].randomElement()! : operation
            return Question(a: Int.random(in: 1...10), b: Int.random(in: 1...10), op: op)
        }
    }
    
    func startSolo() {
        modeDuel = false
        p1Correct = 0; p2Correct = 0
        currentIndex = 0; correctSolo = 0
        generateQuestions()
        isRunning = true; elapsedSec = 0; startTimer()
    }
    func startDuel() {
        modeDuel = true
        p1Correct = 0; p2Correct = 0
        currentIndex = 0
        generateQuestions()
        isRunning = true; elapsedSec = 0; startTimer()
    }
    
    private func startTimer() {
        startDate = Date()
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let s = self, s.isRunning else { return }
                s.elapsedSec = Int(Date().timeIntervalSince(s.startDate))
            }
    }
    
    func submitSolo(answer: Int) {
        guard currentIndex < questions.count else { return }
        let q = questions[currentIndex]
        if q.answer == answer {
            correctSolo += 1
            playSound(name: "clap")
        } else {
            playSound(name: "aww")
        }
        currentIndex += 1
        if currentIndex >= questions.count { finish() }
    }
    
    func submitDuel(answer: Int, player: Int) {
        guard currentIndex < questions.count else { return }
        let q = questions[currentIndex]
        if q.answer == answer {
            if player == 1 { p1Correct += 1 } else { p2Correct += 1 }
            playSound(name: "clap")
        } else {
            playSound(name: "aww")
        }
        // For simplicity, advance after both answered or when both input provided externally
        // Here we just advance after both players tapped their buttons (handled in view logic)
    }
    
    func advanceDuelTurn() {
        currentIndex += 1
        if currentIndex >= questions.count { finish() }
    }
    
    func finish() {
        isRunning = false
        timer?.cancel()
        if modeDuel {
            if p1Correct > p2Correct { winner = "Người chơi 1" }
            else if p2Correct > p1Correct { winner = "Người chơi 2" }
            else { winner = "Hòa" }
        }
    }
    
    private func playSound(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Audio play error:", error)
        }
    }
}

// MARK: - App Entry
@main
struct MMartFunApp: App {
    @StateObject var settings = Settings.shared
    @StateObject var vm = GameViewModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(vm)
        }
    }
}

// MARK: - Views

struct RootView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var vm: GameViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color("PrimaryLight"), Color("PrimaryDark")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text("MMart Fun")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { vm.showLangSelector = true }) {
                        Image(systemName: "globe")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                MainMenu()
                    .padding()
            }
            .sheet(isPresented: $vm.showLangSelector) {
                LanguageSelector()
            }
        }
    }
}

struct MainMenu: View {
    @EnvironmentObject var vm: GameViewModel
    @EnvironmentObject var settings: Settings
    @State private var soloMode = true
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $soloMode) {
                Text("1 Người").tag(true)
                Text("2 Người").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(height: 36)
            
            Picker("Phép", selection: $vm.operation) {
                Text("Nhân").tag(Operation.multiply)
                Text("Chia").tag(Operation.divide)
                Text("Cả hai").tag(Operation.both)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if vm.isRunning {
                if soloMode {
                    SoloPlayView()
                } else {
                    DuelPlayView()
                }
            } else {
                Button(action: { soloMode ? vm.startSolo() : vm.startDuel() }) {
                    Label("Bắt đầu", systemImage: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct SoloPlayView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var answerText = ""
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("⏱ \(timeStr(vm.elapsedSec))")
                Spacer()
                Text("Đúng: \(vm.correctSolo)/\(vm.questions.count)")
            }.foregroundColor(.white)
            if vm.currentIndex < vm.questions.count {
                Text(vm.questions[vm.currentIndex].text(for: Settings.shared.language))
                    .font(.system(size: 46, weight: .heavy))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                TextField("Nhập đáp án", text: $answerText)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .frame(width: 180)
                HStack {
                    Button("Trả lời") {
                        if let v = Int(answerText) {
                            vm.submitSolo(answer: v); answerText = ""
                        }
                    }.buttonStyle(.borderedProminent)
                    Button("Bỏ qua") {
                        vm.currentIndex += 1; answerText = ""
                        if vm.currentIndex >= vm.questions.count { vm.finish() }
                    }.buttonStyle(.bordered)
                }
            } else {
                Text("Hoàn thành!")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }
}

struct DuelPlayView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var a1 = ""
    @State private var a2 = ""
    @State private var leftAnswered = false
    @State private var rightAnswered = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("⏱ \(timeStr(vm.elapsedSec))").foregroundColor(.white)
            if vm.currentIndex < vm.questions.count {
                Text(vm.questions[vm.currentIndex].text(for: Settings.shared.language))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.vertical)
                HStack(spacing: 12) {
                    VStack {
                        Text("Người chơi 1").foregroundColor(.white)
                        TextField("Câu trả lời", text: $a1).keyboardType(.numberPad).padding().background(Color.white).cornerRadius(8).frame(width: 140)
                        Button("Trả lời") {
                            if let v = Int(a1) {
                                vm.submitDuel(answer: v, player: 1)
                                leftAnswered = true
                            }
                        }.buttonStyle(.borderedProminent).tint(.blue)
                        Text("Đúng: \(vm.p1Correct)").foregroundColor(.white)
                    }
                    VStack {
                        Text("Người chơi 2").foregroundColor(.white)
                        TextField("Câu trả lời", text: $a2).keyboardType(.numberPad).padding().background(Color.white).cornerRadius(8).frame(width: 140)
                        Button("Trả lời") {
                            if let v = Int(a2) {
                                vm.submitDuel(answer: v, player: 2)
                                rightAnswered = true
                            }
                        }.buttonStyle(.borderedProminent).tint(.pink)
                        Text("Đúng: \(vm.p2Correct)").foregroundColor(.white)
                    }
                }
                Button("Tiếp") {
                    // advance only when at least one answered (you can change logic)
                    if leftAnswered || rightAnswered {
                        vm.advanceDuelTurn()
                        leftAnswered = false; rightAnswered = false
                        a1 = ""; a2 = ""
                    }
                }.buttonStyle(.bordered)
            } else {
                Text("Hoàn thành!")
            }
            if vm.finished {
                VStack {
                    Image(systemName: "crown.fill").font(.system(size: 72)).foregroundColor(.yellow)
                    Text(vm.winner ?? "").font(.title).foregroundColor(.white)
                }
            }
        }.padding().background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }
}

struct LanguageSelector: View {
    @EnvironmentObject var settings: Settings
    var body: some View {
        VStack(spacing: 20) {
            Text("Chọn ngôn ngữ / Choose language").font(.title2).bold()
            HStack(spacing: 20) {
                Button(action: { settings.language = .vi; UserDefaults.standard.set("vi", forKey: "MMartFun_Lang"); }) {
                    VStack { Text("Tiếng Việt").bold(); Text("Vietnamese") }
                        .padding().frame(width: 140).background(Color.green.opacity(0.9)).cornerRadius(10).foregroundColor(.white)
                }
                Button(action: { settings.language = .en; UserDefaults.standard.set("en", forKey: "MMartFun_Lang"); }) {
                    VStack { Text("English").bold(); Text("English") }
                        .padding().frame(width: 140).background(Color.blue.opacity(0.9)).cornerRadius(10).foregroundColor(.white)
                }
            }
            Text("Bạn có thể đổi ngôn ngữ sau trong cài đặt (biểu tượng quả địa cầu).").font(.caption).multilineTextAlignment(.center).padding()
        }.padding()
    }
}

func timeStr(_ s: Int) -> String { String(format: "%02d:%02d", s/60, s%60) }
