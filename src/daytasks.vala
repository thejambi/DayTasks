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

	private const string shortcutsText = 
			"Enter: Save/update task being edited\n" + 
			"C or X: Mark selected task complete\n" + 
			"Delete: Delete selected task\n" +
			"Ctrl+[1-9]: Prioritize selected task\n" +
			"Ctrl+0: Clear priority on selected task\n" + 
			"R: Reload todo.txt file\n" +
			"Ctrl+F: Toggle the filter";
	
	private int width;
	private int height;
	private string lastKeyName;
	private bool loadingTasks = false;
//	private TextView txtTask;
	private HyperTextView txtTask;
	private TreeView taskListView;
	private TodoTxtFile todoFile;
	private TaskEditor editor;
	private Paned paned;
	private ToolButton completeButton;
	private ToolButton deleteButton;
	private MenuToolButton priorityButton;
	private ToolButton archiveButton;
	private ToggleToolButton filterButton;
	private bool listIsFiltered = false;
	private bool inFilterView = false;

	private Gdk.RGBA selectionColor;
	private Gdk.RGBA filterBgColor;
	private Gdk.RGBA taskBgColor;

	public Main () {

		Zystem.debugOn = !isInstalled;

		UserData.initializeUserData();

		this.lastKeyName = "";

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
		var menuOpenFile = new Gtk.MenuItem.with_label("Open todo folder...");
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

		/*// Set up Help menu
		var helpMenu = new Gtk.Menu();
		var menuKeyboardShortcuts = new Gtk.MenuItem.with_label("Keyboard Shortcuts");
		menuKeyboardShortcuts.activate.connect(() => {
			//showKeyboardShortcuts();
		});
		var menuAbout = new Gtk.MenuItem.with_label("About DayTasks");
		menuAbout.activate.connect(() => {
			//this.menuAboutClicked();
		});
		helpMenu.append(menuKeyboardShortcuts);
		helpMenu.append(menuAbout);*/

//		var helpMenuItem = new Gtk.MenuItem.with_label("Help");
//		helpMenuItem.set_submenu(helpMenu);
		//menubar.append(helpMenuItem);


		// Create toolbar
		var toolbar = new Toolbar();
		toolbar.set_style(ToolbarStyle.TEXT);
		var context = toolbar.get_style_context();
		context.add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

//		var openButton = new ToolButton.from_stock(Stock.OPEN);
		//var openButton = new ToolButton(null, "Open…");
		//openButton.clicked.connect(() => { this.openDirectory(); });

//		var newButton = new ToolButton.from_stock(Stock.ADD);
		var newButton = new ToolButton(null, "New");
		newButton.clicked.connect(() => { this.startNewTask(); });
		
//		this.completeButton = new ToolButton.from_stock(Stock.APPLY);
		this.completeButton = new ToolButton(null, "✓");
		completeButton.clicked.connect(() => { this.markSelectedTaskComplete(); });
		
//		this.deleteButton = new ToolButton.from_stock(Stock.DELETE);
		this.deleteButton = new ToolButton(null, "  ⃠");
		deleteButton.clicked.connect(() => { this.deleteSelectedTask(); });

		this.priorityButton = new MenuToolButton(null, "(A)");
		this.priorityButton.clicked.connect(() => { this.prioritizeSelectedTask('A'); });
		var priorityMenu = new Gtk.Menu();

		string priorities = "BCDEFG";
		foreach (char c in priorities.to_utf8()) {
			var menuP = new Gtk.MenuItem.with_label("(" + c.to_string() + ")");
			menuP.activate.connect(() => { this.prioritizeSelectedTask(c); });
			priorityMenu.append(menuP);
		}
		
		var menuClearP = new Gtk.MenuItem.with_label("Clear Priority");
		menuClearP.activate.connect(() => { this.clearSelectedTaskPriority(); });
		priorityMenu.append(menuClearP);

		priorityMenu.show_all();

		this.priorityButton.set_menu(priorityMenu);

//		this.archiveButton = new ToolButton.from_stock(Stock.JUMP_TO);
		this.archiveButton = new ToolButton(null, "Archive");
		this.archiveButton.clicked.connect(() => { this.archiveCompletedTasks(); });

		this.filterButton = new ToggleToolButton();
		this.filterButton.label = "Filter";
		this.filterButton.toggled.connect(() => {
			this.toggleFilter();
		});

//		var keyboardShortcutsButton = new ToolButton(null, "Keyboard Shortcuts");
//		keyboardShortcutsButton.clicked.connect(() => { this.showKeyboardShortcuts(); });

		var aboutMenuButton = new MenuToolButton(null, "?");

		// Set up About menu
		var aboutMenu = new Gtk.Menu();
		var menuOpenFolder = new Gtk.MenuItem.with_label("Open tasks folder...");
		menuOpenFolder.activate.connect(() => { this.openDirectory(); });
		var menuKeyboardShortcuts = new Gtk.MenuItem.with_label("Keyboard Shortcuts");
		menuKeyboardShortcuts.activate.connect(() => {
			this.showKeyboardShortcuts();
		});
		var menuAbout = new Gtk.MenuItem.with_label("About DayTasks");
		menuAbout.activate.connect(() => {
			this.showAboutDialog();
		});
		aboutMenu.append(menuOpenFolder);
		aboutMenu.append(menuKeyboardShortcuts);
		aboutMenu.append(menuAbout);

		aboutMenuButton.set_menu(aboutMenu);

		aboutMenu.show_all();

		aboutMenuButton.clicked.connect(() => { this.showAboutDialog(); });

		//toolbar.insert(openButton, -1);
		toolbar.insert(newButton, -1);
		toolbar.insert(this.completeButton, -1);
		toolbar.insert(this.deleteButton, -1);
		toolbar.insert(this.priorityButton, -1);
		toolbar.insert(this.archiveButton, -1);
		toolbar.insert(this.filterButton, -1);
//		toolbar.insert(new Gtk.SeparatorToolItem(), -1);
		var separator = new SeparatorToolItem();
		toolbar.add(separator);
		toolbar.child_set_property(separator, "expand", true);
		separator.draw = false;
		toolbar.insert(separator, -1);
		toolbar.insert(aboutMenuButton, -1);
		
		this.txtTask = new HyperTextView();	 // Used to be TextView
		this.txtTask.focus_in_event.connect(() => {
			if (!this.todoFile.hasActiveTask()) {
				this.enableTaskActionButtons(false);
				this.selectNoTasks();
			}
			return false;
		});
		this.editor = new TaskEditor(this.txtTask.buffer);

		this.txtTask.buffer.changed.connect(() => {
			this.filterTasks();
			if (this.newTaskBeingEdited()) {
				this.enablePriorityButton(true);
			}
			this.txtTask.has_focus = true;
		});


		// Elementary hack time
		this.selectionColor = this.txtTask.get_style_context().get_background_color(StateFlags.SELECTED);
		this.taskBgColor = this.txtTask.get_style_context().get_background_color(StateFlags.NORMAL);
		this.filterBgColor = this.get_style_context().get_background_color(StateFlags.NORMAL);

		bool elementaryHackTime = false;
		
		if (this.taskBgColor.to_string() == this.filterBgColor.to_string()) {
			elementaryHackTime = true;
			this.taskBgColor = Gdk.RGBA();
			this.taskBgColor.parse("#FFFFFF");
			Zystem.debug("Hi. Your theme was wrong so I am just using white for you to write on.");
		} else {
			Zystem.debug(this.taskBgColor.to_string());
			Zystem.debug(this.filterBgColor.to_string());
		}

		
		

		this.taskListView = new TreeView();
		this.taskListView.insert_column_with_attributes(-1, "Tasks", new CellRendererText (), "text", 0);

		// Load todoFile and sets up taskListView with list of tasks
		this.openTodoFile();

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
		vbox1.pack_start (paned, true, true, 0);

		add(vbox1);

		
		// Connect keypress signal
		this.key_press_event.connect((window,event) => { 
			return this.onKeyPress(event); 
		});
		
		
		this.destroy.connect(() => { this.on_destroy(); });

		this.startNewTask();
	}

	/**
	 * Don't call this except from openTodoFile().
	 */
	private void setuptaskListView() {
		var listmodel = new ListStore(1, typeof (string));
		this.taskListView.model = listmodel;

		// This is now done when instantiating taskListView
//		this.taskListView.insert_column_with_attributes(-1, "Tasks", new CellRendererText (), "text", 0);

		this.loadTasksList();
		// And start new?

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

		this.todoFile.loadTasksToListStore(listmodel);

		this.loadingTasks = false;

//		this.enableTaskActionButtons(false);
	}

	private void loadListAndStartNew() {
		this.loadTasksList();
		this.startNewTask();
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

		this.todoFile.unsetActiveTask();

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
			this.enableTaskActionButtons(true);
			this.editor.clear();
		}

		Zystem.debug("The selected index is: " + index.to_string());

		if (this.inFilterView && index >= 0) {
			Zystem.debug("In filter view, so I'm exiting it.");
			this.exitFilterView();
		}
	}

	/**
	 * This method called on a double-click of a task, or hitting enter on a selected task.
	 */
	private void openTask(TreePath path, TreeViewColumn col) {
		this.setActiveTask();   // Loads selected task as active task
		
		this.editor.startNewTask(this.todoFile.getActiveTaskText()); // Load task text
		this.txtTask.has_focus = true;
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
//					this.loadListAndStartNew();
					this.manualReloadTodoFile();
					return true;
					break;
				case "z":
					this.editor.undo();
					break;
				case "y":
					this.editor.redo();
					break;
				case "f":
//					this.toggleFilter();
					this.filterButton.active = !this.filterButton.active;
					Zystem.debug("Filter Mode is: " + this.listIsFiltered.to_string());
					break;
				case "p":
					this.archiveCompletedTasks();
					break;
				case "1":
					this.prioritizeSelectedTask('A');
					break;
				case "2":
					this.prioritizeSelectedTask('B');
					break;
				case "3":
					this.prioritizeSelectedTask('C');
					break;
				case "4":
					this.prioritizeSelectedTask('D');
					break;
				case "5":
					this.prioritizeSelectedTask('E');
					break;
				case "6":
					this.prioritizeSelectedTask('F');
					break;
				case "7":
					this.prioritizeSelectedTask('G');
					break;
				case "8":
					this.prioritizeSelectedTask('H');
					break;
				case "9":
					this.prioritizeSelectedTask('I');
					break;
				case "0":
					this.clearSelectedTaskPriority();
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
						this.manualReloadTodoFile();
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

		if (this.taskListView.has_focus) {
			return true;
		}
		
		// Return false or the entry does not get updated.
		return false;
	}

	private void saveActiveTask() {
		if (this.inFilterView) {
			return;
		}
		
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
			this.loadListAndStartNew();
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
		this.loadListAndStartNew();
	}

	private void markSelectedTaskComplete() {
		this.setActiveTask();
		this.todoFile.completeActiveTask();
		this.loadListAndStartNew();
	}

	private void prioritizeSelectedTask(char priority) {
		// This needs to work when there's a new task being edited also. Tricky!
		
		// Handle new task being edited, existing task being edited, and existing task selected.

		if (this.newTaskBeingEdited() || this.existingTaskBeingEdited()) {
			string text = this.editor.getText();
			this.editor.clear();
			this.editor.prepend(Task.changePriorityOnTaskText(text, priority));
		} else {
			this.setActiveTask();
			this.todoFile.prioritizeActiveTask(priority);
			this.loadListAndStartNew();
		}
	}

	private void clearSelectedTaskPriority() {
		// This needs to work when there's a new task being edited also. Tricky!
		
		// Handle new task being edited, existing task being edited, and existing task selected.

		if (this.newTaskBeingEdited() || this.existingTaskBeingEdited()) {
			string text = this.editor.getText();
			this.editor.clear();
			this.editor.prepend(Task.clearPriorityOnTaskText(text));
		} else {
			this.setActiveTask();
			this.todoFile.clearActiveTaskPriority();
			this.loadListAndStartNew();
		}
	}

	private bool noTaskSelected() {
		var selection = this.taskListView.get_selection() as TreeSelection;
		selection.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		return !selection.get_selected(out model, out iter);
	}

	private void selectNoTasks() {
		//this.todoFile.unsetActiveTask(); // Done by taskSelected.
		var selection = this.taskListView.get_selection() as TreeSelection;
		selection.unselect_all();
	}

	private void manualReloadTodoFile() {
		this.todoFile.reload();
		this.setuptaskListView();
		this.enableTaskActionButtons(false);
	}

	private void openTodoFile() {
		this.todoFile = new TodoTxtFile(UserData.todoDirPath);
		this.setuptaskListView();
		this.enableTaskActionButtons(false);
	}

	private void startNewTask() {
		this.todoFile.unsetActiveTask();
		this.unselectTasks();
		this.exitFilterView();
		this.editor.startNewTask("");
		this.txtTask.has_focus = true;
	}

	private void archiveCompletedTasks() {
		this.todoFile.archiveCompletedTasks();
		this.loadListAndStartNew();
	}

	private void toggleFilter() {
		this.listIsFiltered = this.filterButton.active;

		if (this.listIsFiltered) {
			this.enterFilterView();
		} else {
//			if (this.inFilterView) {
				this.exitFilterView();
//			}

			this.todoFile.loadTasksNotFiltered();
			this.loadTasksList();
		}

//		this.txtTask

		/*if (this.filterMode) {
			this.changeEntryBgColor(this.filterBgColor);
			this.startNewTask();
		} else {
			this.changeEntryBgColor(this.taskBgColor);
		}*/
	}

	private void enterFilterView() {
		this.inFilterView = true;
		this.listIsFiltered = true;
		
		this.todoFile.unsetActiveTask();
		this.unselectTasks();
		this.editor.startNewTask("");
		this.txtTask.has_focus = true;
		
		this.changeEntryBgColor(this.filterBgColor);
//		this.startNewTask();
		
	}

	private void exitFilterView() {
		this.inFilterView = false;
		this.todoFile.unsetActiveTask();
		this.editor.startNewTask("");
		this.txtTask.has_focus = true;
		this.changeEntryBgColor(this.taskBgColor);
	}

	private void filterTasks() {
		if (this.inFilterView) {
			this.todoFile.loadTasksFiltered(this.editor.getText());
			this.loadTasksList();
		} /*else if (this.listIsFiltered && this.editor.isEmpty()) {
			this.todoFile.loadTasksNotFiltered();
			this.loadTasksList();
		}*/
	}

	private void changeEntryBgColor(Gdk.RGBA color) {
		this.txtTask.override_background_color(Gtk.StateFlags.NORMAL, color);
		this.txtTask.override_background_color(Gtk.StateFlags.SELECTED, this.selectionColor);
	}
	
	

	public void openDirectory() {
		var fileChooser = new FileChooserDialog("Choose tasks directory", this,
												FileChooserAction.SELECT_FOLDER,
												Stock.CANCEL, ResponseType.CANCEL,
												Stock.OPEN, ResponseType.ACCEPT);
		if (fileChooser.run() == ResponseType.ACCEPT) {
			string path = fileChooser.get_filename();
			UserData.setTasksDir(path);
			
//			this.reloadTodoFile();
			this.openTodoFile();
		}
		fileChooser.destroy();
	}

	private void enableTaskActionButtons(bool isEnabled) {
		Zystem.debug("Enable task action buttons: " + isEnabled.to_string());
//		if (!this.listIsFiltered) {
			this.completeButton.set_sensitive(isEnabled);
			this.deleteButton.set_sensitive(isEnabled);
			//this.priorityButton.set_sensitive(isEnabled); // Priority button handled by enablePriorityButton function
//		}
	}

	private void enablePriorityButton(bool isEnabled) {
		this.priorityButton.set_sensitive(isEnabled);
	}

	private bool newTaskBeingEdited() {
		return !this.todoFile.hasActiveTask() && this.noTaskSelected();  // Doing it this way, empty is ok?
	}

	private bool existingTaskBeingEdited() {
		return this.todoFile.hasActiveTask() && !this.editor.isEmpty() && !this.noTaskSelected();
	}

	private void showKeyboardShortcuts() {
		var dialog = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL,Gtk.MessageType.INFO, 
						Gtk.ButtonsType.OK, this.shortcutsText);
		dialog.set_title("Keyboard Shortcuts");
		dialog.run();
		dialog.destroy();
	}

	private void showAboutDialog() {
		var about = new AboutDialog();
		about.set_program_name("DayTasks");
		about.comments = "A minimal todo app compatible with todo.txt.\nFor more about that, see www.todotxt.com.";
		about.website = "http://burnsoftware.wordpress.com/daytasks";
		about.logo_icon_name = "daytasks";
		about.set_copyright("by Zach Burnham");
		about.run();
		about.hide();
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

