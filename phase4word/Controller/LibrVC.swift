//
//  LibrVC.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/20/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import RealmSwift
import CryptoSwift

class LibrVC: UIViewController {

    
    @IBOutlet weak var tableView: UITableView!
    
    
    
    @IBOutlet weak var powrButton: UIButton!
    var selectedNotes: [Note] = []
    var sortedNotes: [Note] = []
    
    var state: State!
    
    required init? (coder aDecoder: NSCoder) {
        state = State(game: mood, players: players)
        super.init(coder: aDecoder)
    }
    
    var sortMood: SortState = .timeDescending
    var powr: Bool = false
    
    let defaultBackgroundColor = UIColor(displayP3Red: 0.1, green: 0.0, blue: 0.3, alpha: 0.1)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("librVC did load")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        /* Just testing some progInt. Memory usage is up to 83MB after 1000 hash, encryption, and decryption operations
        print("begin hashing")
        var textToHash = "This is just a string of text to hash".sha256()
        let crypto = CryptoService.shared
        let digest = "digest this".sha256()
        let plaintext = "This is a story all about how my life was turned upside down."
        
        DispatchQueue.global(qos: .background).async {
            for i in 1...1000 {
                var lastHash = textToHash
                textToHash = textToHash.sha256()
                let (key, _) = crypto.shaDivider(digest: lastHash)!
                let iv = crypto.cha20IvMaker(digest: digest)
                
                let cipherText = try! ChaCha20(key: key, iv: iv).encrypt(Array(lastHash.utf8))
         
                print(i, "ctext:", cipherText)
                
                print(i, ":", lastHash)
                
                let decrypted = try! ChaCha20(key: key, iv: iv).decrypt(cipherText)
                let decString = String(bytes: decrypted, encoding: .utf8)!
                print(i, "ptextclist:", decrypted)
                print(i, "ptextstr:", decString)
                assert(decString == lastHash, "assertion passes")
                
            }
            
            DispatchQueue.main.async {
                print("DispatchQueue.main.async: finished hashing")
            }
        }
        
        print("finished hashing")
        */
        
//        let realm = RealmService.shared.realm
//        notes = realm.objects(Note.self)
//        selectedNote = notes[0]
//        print(notes.count)
        
        switch state.game {
        case .Library:
            powrButton.isEnabled = false
        case .Powering:
            powrButton.isEnabled = true
        default: break
        }
        sortedNotes = state.orderedNotes
        
        tableView.reloadData()
        
        
    }
    @IBAction func greenTapped(_ sender: Any) {
        if sortMood == .greenAscending {
            sortedNotes = state.orderedNotes.sorted(by: { (lhs, rhs) -> Bool in
                lhs.green <= rhs.green
            })
            sortMood = .greenDescending
            print("state.orderedNotes:", state.orderedNotes.count)
        } else {
            sortedNotes = state.orderedNotes.sorted(by: { (lhs, rhs) -> Bool in
                lhs.green >= rhs.green
            })
            sortMood = .greenAscending
            print("state.orderedNotes:", state.orderedNotes.count)
        }
        tableView.reloadData()
    }
    
    
    @IBAction func timeTapped(_ sender: Any) {
        if sortMood == .timeAscending {
            sortedNotes = state.orderedNotes.sorted(by: { (lhs, rhs) -> Bool in
                lhs.time < rhs.time
            })
            sortMood = .timeDescending
            print("state.orderedNotes:", state.orderedNotes.count)
        } else {
            sortedNotes = state.orderedNotes.sorted(by: { (lhs, rhs) -> Bool in
                lhs.time > rhs.time
            })
            sortMood = .timeAscending
            print("state.orderedNotes:", state.orderedNotes.count)
        }
        tableView.reloadData()
    }
    
    
//    @IBAction func xTapped(_ sender: Any) {
//        if sortedNotes == state.orderedNotes {
//            sortedNotes = []
//            deselectAllCells()
//        } else {
//            sortedNotes = state.orderedNotes
//            selectAllCells()
//        }
//
//    }
    
    

    
    enum SortState {
        case greenDescending, greenAscending, timeDescending, timeAscending
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "librToNote" {
            let noteVC: NoteVC = segue.destination as! NoteVC
            noteVC.state = state
//            noteVC.state.game = .ToNote
            let saveState = Save(counter: state.counter, green: state.green, notes: state.notes!, buffer: state.buffer, state: state)
            RealmService.shared.create(saveState)
        }
        
        if segue.identifier == "powrBackToNote" {
            let noteVC: NoteVC = segue.destination as! NoteVC
            state.game = .ToNote
            noteVC.state = state
        }
        
        if segue.identifier == "powrPack" {
            let noteVC: NoteVC = segue.destination as! NoteVC
            state.jsonData = try! notesToJSON(notes: selectedNotes)
            print("powrPack state.green", state.green)
            noteVC.state = state
            noteVC.state.game = .WillPower
            print("powrPack", noteVC.state.game)
            noteVC.state.currentNote = noteVC.blankNote(data: "\(selectedNotes.count) Notes selected. Before mplying to share this Notebook, type an invitation code in the header above.", meta: "", green: 0)
//            print(noteVC.state.currentNote)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override var prefersStatusBarHidden: Bool {
        return true
    }
    var allowsMultipleSelectionDuringEditing: Bool {
        return true
    }
    
    func notesToJSON(notes: [Note]) throws -> Data {
        let data = try! JSONEncoder().encode(notes)
        return data
    }
}

extension LibrVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("notes:", notes.count, "onotes:", state.orderedNotes.count)
        return sortedNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: LibrCell = tableView.dequeueReusableCell(withIdentifier: "librCell", for: indexPath) as! LibrCell
        
        
        let note = sortedNotes[indexPath.row]
        cell.configure(with: note, row: indexPath.row)
        
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(displayP3Red: 0.1, green: 0, blue: 0.3, alpha: 0.1)
        }
        
        return cell
    }
    
    // TODO: tap row to display note annotation. then tap annotation to segue to note
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("row tapped", indexPath.row)
        if state.game == .Library {
            state.currentNote = sortedNotes[indexPath.row]
            performSegue(withIdentifier: "librToNote", sender: self)
        } else {
            if let cell = tableView.cellForRow(at: indexPath) {
                let selectedBG = UIColor(displayP3Red: 0.5, green: 0.0, blue: 0.5, alpha: 0.25)
                let noteToAdd = sortedNotes[indexPath.row]
            
                if !selectedNotes.contains(noteToAdd) {
                    selectedNotes.append(noteToAdd)
                    cell.backgroundColor = selectedBG
                }

            }
        }
        
    }
    
//    func selectAllCells() {
//        let selectedBG = UIColor(displayP3Red: 0.5, green: 0.0, blue: 0.5, alpha: 0.25)
//
//        for index in 0..<state.orderedNotes.count {
//            if state.orderedNotes[index].green > 1 {
//                let indexPath = IndexPath(item: index, section: 0)
//                let cell = tableView.cellForRow(at: indexPath)
//
//                cell?.backgroundColor = selectedBG
//            }
//        }
//
//        selectedNotes = sortedNotes
//    }
//
//    func deselectAllCells() {
//        for index in 0..<state.orderedNotes.count {
//            let indexPath = IndexPath(item: index, section: 0)
//            let cell = tableView.cellForRow(at: indexPath)
//
//            cell?.backgroundColor = defaultBackgroundColor
//        }
//
//        selectedNotes = []
//    }
    
    func blankNote(data: String, meta: String, green: Int) -> Note {
        return Note(green: green, ssi: "ssi".data(using: .utf8)!, address: "address", signature: "signature", digest: "digest", longitude: 42.0, latitude: -42.0, time: Date(), data: data, meta: meta)
    }
    
//    func selectRow(at indexPath: IndexPath?,
//                   animated: Bool,
//                   scrollPosition: UITableViewScrollPosition) {
//        print("selecting row \((indexPath?.row)! + 1)")
//
//        print("bgcolor:", defaultBackgroundColor)
//        if let cell = tableView.cellForRow(at: indexPath!) {
//            let selectedBG = UIColor(displayP3Red: 0.5, green: 0.0, blue: 0.5, alpha: 0.25)
//            cell.backgroundColor = selectedBG
//            if cell.backgroundColor == selectedBG {
//                cell.backgroundColor = defaultBackgroundColor
//            }
//        }
//    }
    
    
    
    
}
