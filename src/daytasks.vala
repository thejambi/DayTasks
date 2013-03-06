/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c
 * Copyright (C) 2012 Zach Burnham <thejambi@gmail.com>
 * 
 * DayTasks is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * DayTasks is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

public class Main : Window {

	// SET THIS TO TRUE BEFORE BUILDING TARBALL
	private const bool isInstalled = false;
	
	private int width;
	private int height;
	private string lastKeyName;
	private bool loadingTasks = false;
	private TextView txtTask;
	private TreeView taskListView;
	private TodoTxtFile todoFile;
	private TaskEditor editor;
	private Paned paned;
	private ToolButton completeButton;
	private ToolButton deleteButton;

	public Main () {

		Zystem.debugOn = !isInstalled;

		UserData.initializeUserData();

		this.lastKeyName = "";

//		this.loadTodoFile();

		this.title = "DayTasks";
		this.window_position = WindowPosition.CENTER;
		set_default_size(UserData.windowWidth, UserData.windowHeight);

		this.configure_event.connect(() => {
			// Record window size
			this.get_size(out this.width, out this.height);
			return false;
		});

		
		// Create menu
		var menubar = new MenuBar();

		var tasksMenu = new Gtk.Menu();
		var menuOpenFile = new Gtk.MenuItem.with_label("Open todo.txt file");
		menuOpenFile.activate.connect(() => {
			this.openDirectory();
		});
//		tasksMenu.append(menuOpenFile);
		
		Gtk.MenuItem tasksMenuItem = new Gtk.MenuItem.with_label("Tasks");
		tasksMenuItem.set_submenu(tasksMenu);
		menubar.append(tasksMenuItem);

		// Set up Settings menu
		var settingsMenu = new Gtk.Menu();
		var menuIncreaseFontSize = new Gtk.MenuItem.with_label("Increase font size");
		menuIncreaseFontSize.activate.connect(() => {
			//this.increaseFontSize();
		});
		var menuDecreaseFontSize = new Gtk.MenuItem.with_label("Decrease font size");
		menuDecreaseFontSize.activate.connect(() => {
			//this.decreaseFontSize();
		});
		settingsMenu.append(menuIncreaseFontSize);
		settingsMenu.append(menuDecreaseFontSize);

		Gtk.MenuItem settingsMenuItem = new Gtk.MenuItem.with_label("Settings");
		settingsMenuItem.set_submenu(settingsMenu);
		//menubar.append(settingsMenuItem);

		// Set up Help menu
		var helpMenu = new Gtk.Menu();
		var menuKeyboardShortcuts = new Gtk.MenuItem.with_label("Keyboard Shortcuts");
		menuKeyboardShortcuts.activate.connect(() => {
			//showKeyboardShortcuts();
		});
		var menuAbout = new Gtk.MenuItem.with_label("About P.S. Notes.");
		menuAbout.activate.connect(() => {
			//this.menuAboutClicked();
		});
		helpMenu.append(menuKeyboardShortcuts);
		helpMenu.append(menuAbout);

		var helpMenuItem = new Gtk.MenuItem.with_label("Help");
		helpMenuItem.set_submenu(helpMenu);
		//menubar.append(helpMenuItem);


		// Create toolbar
		var toolbar = new Toolbar();

		var openButton = new ToolButton(null, "Open...");
		openButton.clicked.connect(() => { this.openDirectory(); });

		var newButton = new ToolButton(null, "New Task");
		newButton.clicked.connect(() => { this.startNewTask(); });
		
		this.completeButton = new ToolButton(null, "Complete");
		completeButton.clicked.connect(() => { this.markSelectedTaskComplete(); });
		
		this.deleteButton = new ToolButton(null, "Delete");
		deleteButton.clicked.connect(() => { this.deleteSelectedTask(); });

		toolbar.insert(openButton, -1);
		toolbar.insert(newButton, -1);
		toolbar.insert(this.completeButton, -1);
		toolbar.insert(this.deleteButton, -1);
		
		this.txtTask = new TextView();
		this.txtTask.focus_in_event.connect(() => {
			if (!this.todoFile.hasActiveTask()) {
				this.enableTaskActionButtons(false);
			}
			return false;
		});
		/*this.txtTask.focus_out_event.connect(() => {
			if (!this.todoFile.hasActiveTask()) {
				this.enableTaskActionButtons(true);
			}
			return false;
		});*/
		/*this.txtTask.buffer.changed.connect(() => {
			//onTextChanged(this.txtTask.buffer);
			Zystem.debug("The text has changed!");
		});*/
		this.editor = new TaskEditor(this.txtTask.buffer);

		this.taskListView = new TreeView();
		this.taskListView.insert_column_with_attributes(-1, "Tasks", new CellRendererText (), "text", 0);

		// Load todoFile and sets up taskListView with list of tasks
		this.reloadTodoFile();

		this.editor = new TaskEditor(this.txtTask.buffer);
		this.txtTask.pixels_above_lines = 2;
		this.txtTask.pixels_below_lines = 2;
		this.txtTask.pixels_inside_wrap = 4;
		this.txtTask.wrap_mode = WrapMode.WORD_CHAR;
		this.txtTask.left_margin = 4;
		this.txtTask.right_margin = 4;
		this.txtTask.accepts_tab = true;
		

		var scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = ShadowType.ETCHED_OUT;
		scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.min_content_width = 251;
		scroll.min_content_height = 280;
		scroll.add (this.taskListView);
		scroll.expand = true;

		this.paned = new Paned(Orientation.VERTICAL);
		paned.add1(txtTask);
		paned.add2(scroll);
		paned.position = 60;

		var vbox1 = new Box (Orientation.VERTICAL, 0);
//		vbox1.pack_start(menubar, false, true, 0);
		vbox1.pack_start(toolbar, false, true, 0);
		vbox1.pack_start (paned, true, true, 2);

		add(vbox1);

		
		// Connect keypress signal
		this.key_press_event.connect((window,event) => { 
			return this.onKeyPress(event); 
		});
		
		
		this.destroy.connect(() => { this.on_destroy(); });

	}

	private void setuptaskListView() {
		var listmodel = new ListStore(1, typeof (string));
		this.taskListView.model = listmodel;

		// This is now done when instantiating taskListView
//		this.taskListView.insert_column_with_attributes(-1, "Tasks", new CellRendererText (), "text", 0);

		this.loadTasksList();

		var treeSelection = this.taskListView.get_selection();
		treeSelection.set_mode(SelectionMode.SINGLE);
		treeSelection.changed.connect(() => {
			taskSelected(treeSelection);
		});
		this.taskListView.row_activated.connect(this.openTask);
	}

	private void loadTasksList() {		
		Zystem.debug("Loading Tasks!");
		this.loadingTasks = true;

		var listmodel = this.taskListView.get_model() as ListStore;
		listmodel.clear();
		//listmodel.set_sort_column_id(0, SortType.ASCENDING);  // No sorting! The TodoTxtFile handles that

		todoFile.loadTasksToListStore(listmodel);

		this.loadingTasks = false;
	}

	private void unselectTasks() {
		var selection = this.taskListView.get_selection() as TreeSelection;
		selection.unselect_all();
		this.enableTaskActionButtons(false);
	}

	private void taskSelected(TreeSelection treeSelection) {
		if (this.loadingTasks) {
			return;
		}

		this.editor.clear();

		this.todoFile.unsetActiveTask();
		
		this.enableTaskActionButtons(true);

		/*int index = -1;
		var selection = this.taskListView.get_selection() as TreeSelection;
		selection.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		if (!selection.get_selected(out model, out iter)) {
			index = -1;
		} else {
			TreePath path = model.get_path(iter);
			index = int.parse(path.to_string());
		}

		Zystem.debug("The selected index is: " + index.to_string());

		Task task = this.todoFile.getTaskAtIndex(index);
		Zystem.debug(task.fullText);

		this.todoFile.changeActiveTask(index);*/
	}

	/**
	 * This method called on a double-click of a task, or hitting enter on a selected task.
	 */
	private void openTask(TreePath path, TreeViewColumn col) {
		// activeTask is decided when the row was selected or clicked first time
		// NO, THAT'S NOT TRUE ANYMORE! DON'T LISTEN TO THAT ^^^

		this.setActiveTask();
		
		this.editor.startNewTask(this.todoFile.getActiveTaskText()); // Load task text
    }

	private void setActiveTask() {
		// Set active task
		int index = -1;
		var selection = this.taskListView.get_selection() as TreeSelection;
		selection.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		if (!selection.get_selected(out model, out iter)) {
			index = -1;
		} else {
			TreePath path = model.get_path(iter);
			index = int.parse(path.to_string());
		}

		Zystem.debug("The active task index is: " + index.to_string());

		Task task = this.todoFile.getTaskAtIndex(index);
		Zystem.debug(task.fullText);

		this.todoFile.changeActiveTask(index);
	}

	public bool onKeyPress(Gdk.EventKey key) {
		uint keyval;
        keyval = key.keyval;
		Gdk.ModifierType state;
		state = key.state;
		bool ctrl = (state & Gdk.ModifierType.CONTROL_MASK) != 0;
		bool shift = (state & Gdk.ModifierType.SHIFT_MASK) != 0;

		string keyName = Gdk.keyval_name(keyval);
		
		// Zystem.debug("Key:\t" + keyName);

		if (ctrl && shift) { // Ctrl+Shift+?
			Zystem.debug("Ctrl+Shift+" + keyName);
			switch (keyName) {
				case "Z":
					//this.editor.redo();
					Zystem.debug("Y'all hit Ctrl+Shift+Z");
					break;
				default:
					Zystem.debug("What should Ctrl+Shift+" + keyName + " do?");
					break;
			}
		}
		else if (ctrl) { // Ctrl+?
			switch (keyName) {
				case "Return":
					if (this.txtTask.has_focus) {
						this.saveActiveTask();
						return true;
					} else {
						Zystem.debug("No saving task for you!");
					}
					break;
				case "r":
					this.reloadTodoFile();
					return true;
					break;
				case "z":
					this.editor.undo();
					break;
				case "y":
					this.editor.redo();
					break;
				default:
					Zystem.debug("What should Ctrl+" + keyName + " do?");
					break;
			}
		}
		else if (!(ctrl || shift/* || keyName == this.lastKeyName*/)) { // Just the one key
			switch (keyName) {
				case "Delete":
					if (this.taskListView.has_focus) {
						Zystem.debug("DELETING TASK");
						this.deleteSelectedTask();
					} else {
						Zystem.debug("No deleting!");
					}
					break;
				case "Return":
					if (this.txtTask.has_focus) {
						this.saveActiveTask();
						return true;
					} else if (this.taskListView.has_focus) {
						return false;
					} else {
						Zystem.debug("No saving task for you!");
					}
					break;
				case "c":
				case "x":
					if (this.taskListView.has_focus) {
						this.markSelectedTaskComplete();
						return true;
					} else {
						Zystem.debug("Not marking task complete.");
					}
					break;
				case "r":
					if (!this.txtTask.has_focus) {
						this.reloadTodoFile();
						return true;
					} else {
						return false;
					}
					break;
				default:
					break;
			}
		}

		// Handle escape key
		if (!(ctrl || shift) && keyName == "Escape") {
			this.on_destroy();  // Quit it!
		}

		this.lastKeyName = keyName;
		
		// Return false or the entry does not get updated.
		return false;
	}

	private void saveActiveTask() {
		if (this.editor.isEmpty()) {
			Zystem.debug("I'm not going to update your empty task...");
		} else {
			Zystem.debug("Updating text of task!!!");
			// If has active task, update it. If no set active task, add new task.
			if (this.todoFile.hasActiveTask()) {
				this.todoFile.updateActiveTaskText(this.editor.getText());
			} else {
				this.todoFile.addNewTask(this.editor.getText());
			}
			this.editor.startNewTask("");
			this.reloadTodoFile();
		}
	}

	private void deleteSelectedTask() {
		// Dialog if ok to delete
		/*var dialog = new Dialog.with_buttons("Delete Task?", null, 0, Stock.OK, ResponseType.OK, null);
		dialog.show_all();*/
		Zystem.debug("GOING TO DELETE NOW");
		this.setActiveTask();
		this.todoFile.deleteActiveTask();
//		this.todoFile.saveFile();
		this.reloadTodoFile();
	}

	private void markSelectedTaskComplete() {
		this.setActiveTask();
		this.todoFile.completeActiveTask();
		this.reloadTodoFile();
	}

	private void reloadTodoFile() {
		this.todoFile = new TodoTxtFile(UserData.getTodoFilePath());
		this.setuptaskListView();
		this.enableTaskActionButtons(false);
	}

	private void startNewTask() {
		this.todoFile.unsetActiveTask();
		this.unselectTasks();
		this.editor.startNewTask("");
		this.txtTask.has_focus = true;
	}
	

	public void openDirectory() {
		var fileChooser = new FileChooserDialog("Choose tasks directory", this,
												FileChooserAction.SELECT_FOLDER,
												Stock.CANCEL, ResponseType.CANCEL,
												Stock.OPEN, ResponseType.ACCEPT);
		if (fileChooser.run() == ResponseType.ACCEPT) {
			string path = fileChooser.get_filename();
			UserData.setTasksDir(path);
			
			this.reloadTodoFile();
		}
		fileChooser.destroy();
	}

	private void enableTaskActionButtons(bool isEnabled) {
		this.completeButton.set_sensitive(isEnabled);
		this.deleteButton.set_sensitive(isEnabled);
	}
	

	












	

	public void on_destroy() {
		Gtk.main_quit();
	}

	static int main (string[] args) 
	{
		Gtk.init (ref args);

		var window = new Main();
		window.show_all();

		Gtk.main ();
		
		return 0;
	}
}

