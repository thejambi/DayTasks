/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/* DayTasks
 *
 * Copyright (C) 2013 Zach Burnham <thejambi@gmail.com>
 *
DayTasks is free software: you can redistribute it and/or modify it
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

public class TodoTxtFile : GLib.Object {

	private string filePath;
	private File todoFile;
	private int activeTaskIndex;
	private List<Task> taskList;
	
	
	// Constructor
	public TodoTxtFile(string path) {
		this.filePath = path;
		this.todoFile = File.new_for_path(this.filePath);
		this.loadTaskList();
		this.sortByPriority();
		this.unsetActiveTask();
	}

	public void loadTaskList() {	
		Zystem.debug("Loading the task list");

		this.taskList = new List<Task>();

		File file = File.new_for_path(this.filePath);
		try {
			if (file.query_exists() == true) {
				var dis = new DataInputStream (file.read ());
				string line;
				// Read lines until end of file (null) is reached
				while ((line = dis.read_line (null)) != null) {
					//stdout.printf ("%s\n", line);
					Zystem.debug(line);
					taskList.append(new Task(line));
				}
			}
		} catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
	}

	/**
	 * Sort the list so prioritized tasks are sorted at the beginning and completed tasks are at the end.
	 */
	public void sortByPriority() {
		Zystem.debug("Sorting by PRIORITY!");
		this.taskList.sort((task, otherTask) => {
			// If a task is complete, send to bottom
			if (task.isComplete) {
				return 1;	// send task to bottom
			}
			else if (otherTask.isComplete) {
				return -1;	// send otherTask to bottom
			}

			// If both have no priority, it's a tie
			if (task.priority == ' ' && otherTask.priority == ' ') {
				return 0;
			}

			// If a task has priority, compare and send to top
			// We know one must have a priority if the code gets here
			if (task.priority == ' ') {
				// Send otherTask to top because it has priority
				return 1;
			}
			else if (otherTask.priority == ' ') {
				// Send task to top because it has priority
				return -1;
			}
			else if (task.priority > otherTask.priority) {
				return 1;	// send task to bottom
			}

			return 0;
		});
	}

	public string changeActiveTask(int index) {
		this.activeTaskIndex = index;
		return this.taskList.nth_data(index).fullText;
	}

	public string getActiveTaskText() {
		return this.taskList.nth_data(this.activeTaskIndex).fullText;
	}

	public void updateActiveTaskText(string text) {
		this.taskList.nth_data(this.activeTaskIndex).updateTaskText(text);
		this.debug();
	}

	public void debug() {
		Zystem.debug("SUPER DEBUG!!!!!");
		foreach (Task t in this.taskList) {
			Zystem.debug(t.fullText);
		}
	}

	public void loadTasksToListStore(ListStore listmodel) {
		TreeIter iter;
		// Go through the list
		foreach (Task task in this.taskList) {
			listmodel.append(out iter);
			listmodel.set(iter, 0, task.displayText);
			Zystem.debug("Added: " + task.displayText);
		}
	}

	public void saveFile() {
		string fileText = this.generateTodoFileText();

		Zystem.debug("ACTUALLY SAVING FILE");
		this.todoFile.replace_contents(fileText.data, null, false, FileCreateFlags.NONE, null, null);
	}

	private string generateTodoFileText() {
		string fileText = "\n";
		foreach (Task task in this.taskList) {
			fileText += task.fullText + "\n";
		}

		fileText = fileText.strip();

		Zystem.debug("Full todo text is......\n\n");
		Zystem.debug(fileText);
		return fileText;
	}

	public void unsetActiveTask() {
		this.activeTaskIndex = -1;
	}

	public Task getTaskAtIndex(int index) {
		return this.taskList.nth_data(index);
	}

}

