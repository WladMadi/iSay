import UIKit
import Speech

class ViewController: UIViewController {

    var recRequest: SFSpeechAudioBufferRecognitionRequest? //обработка процесса распознания, точка аудиовхода
    var recTask: SFSpeechRecognitionTask? //процесс распознания
    let audioEngine = AVAudioEngine () // Аудиодвижок - для работы с микрофоном
    
    @IBOutlet weak var sayTextVeiw: UITextView!
    @IBOutlet weak var putsLabel: UILabel!
    @IBOutlet weak var recordButtonOutlet: UIButton!
    
    
    let speechRec = SFSpeechRecognizer (locale: Locale.init(identifier: "ru"))
    
    @IBAction func startRecorsButton(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recRequest?.endAudio()
            recordButtonOutlet.isEnabled = false
            recordButtonOutlet.setTitle("ЗАПИСЬ", for: .highlighted)
        }else{
            recordStart()
            recordButtonOutlet.setTitle("СТОП", for: .normal)
        }
    }
    
    func recordStart() {
        if recTask != nil {
            recTask?.cancel()
            recTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        }catch{
            print ("Не удалось найти аудиосессию")
        }
        
        recRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Аудиодвижок не имеет входного узла")
        }
        
        guard let recRequest = recRequest else {
            fatalError("Невожможно создать экземпляр запроса")
        }
        
        recRequest.shouldReportPartialResults = true
        
        recTask = speechRec?.recognitionTask(with: recRequest){
            result, error in
            var isFinal = false
            
            if result != nil {
                self.sayTextVeiw.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recRequest = nil
                self.recTask = nil
                
                self.recordButtonOutlet.isEnabled = true
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format){
            buffer, _ in
            self.recRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }catch{
            print ("Не удаётся запустить аудиодвижок")
        }
        
    sayTextVeiw.text = "Помедленнее я всё же записываю!!!"
            
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButtonOutlet.isEnabled = false
        
        SFSpeechRecognizer.requestAuthorization {
            status in
            var buttonState = false
            
            switch status {
            case.authorized:
                buttonState = true
                print ("Разрешение получено")
            
            case.denied:
                buttonState = false
                print("Пользователь не дал разрешения на использование распознавания речи")
                
            case.notDetermined:
                buttonState = false
                print("Пользователь пока не разрешил распознавание речи")
                
            case.restricted:
                buttonState = false
                print("Распознавание речи не поддерживается на этом устройстве")
            }
            DispatchQueue.main.async {
                self.recordButtonOutlet.isEnabled = buttonState
            }
        }
        
        sayTextVeiw.isEditable = false
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButtonOutlet.isEnabled = true
        }else{
            recordButtonOutlet.isEnabled = false}
    }
}



