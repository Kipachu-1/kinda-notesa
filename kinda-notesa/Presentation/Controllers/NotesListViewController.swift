import UIKit
import CoreData

class NotesListViewController: UIViewController, UISearchBarDelegate {
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(NoteTableViewCell.self, forCellReuseIdentifier: NoteTableViewCell.reuseIdentifier)
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        return table
    }()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Search Notes"
        return sc
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(systemName: "note.text"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        
        let titleLabel = UILabel()
        titleLabel.text = "No Notes Yet"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap the + button to create your first note"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    private var notes: [Note] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotes()
    }
    
    private func setupUI() {
        title = "Notes"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewNote)
        )
        
        // Set the UISearchController as the title view and table header
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        tableView.tableHeaderView = searchController.searchBar
        self.navigationItem.searchController?.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search notes"
        searchController.searchBar.searchTextField.textColor = .label
        searchController.searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true

        
        view.addSubview(tableView)
        
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    var initload: Bool = true
    
    private func loadNotes(searchText: String? = nil) {
        notes = CoreDataManager.shared.fetchNotes(searchText: searchText)
        
        // If no notes exist, create a sample note
        if notes.isEmpty && initload {
            _ = CoreDataManager.shared.createNote(title: "Welcome", content: "Start creating your notes!")
            notes = CoreDataManager.shared.fetchNotes()
            
        }
        initload = false
        
        
        updateEmptyState()
        tableView.reloadData()
    }
    
    private func updateEmptyState() {
        if notes.isEmpty && initload {
            view.addSubview(emptyStateView)
            NSLayoutConstraint.activate([
                emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
                emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            tableView.isHidden = true
        } else {
            emptyStateView.removeFromSuperview()
            tableView.isHidden = false
        }
    }
    
    @objc private func addNewNote() {
        let noteDetailVC = NoteDetailViewController(note: nil)
        noteDetailVC.delegate = self
        let navController = UINavigationController(rootViewController: noteDetailVC)
        present(navController, animated: true)
    }
}

extension NotesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.reuseIdentifier, for: indexPath) as? NoteTableViewCell else {
            fatalError("Could not dequeue NoteTableViewCell")
        }
        
        let note = notes[indexPath.row]
        cell.configure(with: note)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = notes[indexPath.row]
        let noteDetailVC = NoteDetailViewController(note: note)
        noteDetailVC.delegate = self
        let navController = UINavigationController(rootViewController: noteDetailVC)
        present(navController, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let note = self.notes[indexPath.row]
            CoreDataManager.shared.deleteNote(note)
            self.notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
            completionHandler(true)
        }
        
        let duplicateAction = UIContextualAction(style: .normal, title: "Duplicate") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let note = self.notes[indexPath.row]
            _ = CoreDataManager.shared.createNote(
                title: "Copy of \(note.title ?? "Note")",
                content: note.content ?? ""
            )
            self.loadNotes()
            completionHandler(true)
        }
        duplicateAction.backgroundColor = .systemBlue
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, duplicateAction])
        return configuration
    }
    
}


extension NotesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.3)
    }
    
    @objc private func performSearch() {
        let searchText = searchController.searchBar.text
        loadNotes(searchText: searchText)
    }
}

extension NotesListViewController: NoteDetailViewControllerDelegate {
    func didSaveNote() {
        loadNotes()
    }
}

extension NotesListViewController {
    private func setupQuickNoteButton() {
        let quickNoteButton = UIButton(type: .system)
        quickNoteButton.setImage(UIImage(systemName: "plus.square.fill"), for: .normal)
        quickNoteButton.tintColor = .systemBlue
        quickNoteButton.addTarget(self, action: #selector(addQuickNote), for: .touchUpInside)
        
        // Position the button in the bottom right corner
        quickNoteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(quickNoteButton)
        
        NSLayoutConstraint.activate([
            quickNoteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            quickNoteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            quickNoteButton.widthAnchor.constraint(equalToConstant: 60),
            quickNoteButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func addQuickNote() {
        let alertController = UIAlertController(title: "Quick Note", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Note Title"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Note Content"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let titleField = alertController.textFields?[0],
                  let contentField = alertController.textFields?[1],
                  let title = titleField.text, !title.isEmpty else {
                return
            }
            
            _ = CoreDataManager.shared.createNote(
                title: title,
                content: contentField.text ?? ""
            )
            
            self?.loadNotes()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

