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

using Gee;

public class Task : GLib.Object, Comparable<Task> {

	// Variables
	public string fullText { get; private set; default = " "; }
	public string displayText { get; private set; default = " "; }
	public unichar priority { get; private set; default = ' '; }
	public bool isComplete { get; private set; default = false; }
	public bool hasCreationDate { get; private set; default = false; }
	public bool hasCompletionDate { get; private set; default = false; }
	private DateTime creationDate;
	private DateTime completionDate;

	public static const string yyyymmddRegexString = "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]";
	
	// Constructor
	public Task(string text) {
		this.fullText = text;
		this.loadPriority();
		this.loadCompleted();
		this.loadCreationDate();
		this.setDisplayText();
	}

	/*
	public Task.CreatedToday(string text) {
		this.fullText = text;
		this.setCreatedToday();
	}*/

	public void loadPriority() {
		if (GLib.Regex.match_simple("[(][A-Z][)]", this.fullText.substring(0, 3))) {
			//Zystem.debug("IT'S GOT PRIORITY!  " + this.fullText.get_char(1).to_string());
			this.priority = this.fullText.get_char(1);
		}
	}

	public void loadCreationDate() {
		if (this.hasPriority()) {
			if (this.fullText.substring(3, 1) == " " && GLib.Regex.match_simple(yyyymmddRegexString, this.fullText.substring(4, 10))) {
				//Zystem.debug("Is this the date string?: " + this.fullText.substring(3, 11));
				//			Zystem.debug("FOUND CREATION DATE");
				this.hasCreationDate = true;
				this.creationDate = new DateTime.local(int.parse(this.fullText.substring(4, 4)), 
				                                       int.parse(this.fullText.substring(9, 2)), 
				                                       int.parse(this.fullText.substring(12, 2)), 0, 0, 0);
			}
		}
		else {
			if (GLib.Regex.match_simple(yyyymmddRegexString, this.fullText.substring(0, 10))) {
				//Zystem.debug("Is this the date string?: " + this.fullText.substring(0, 10));
				//Zystem.debug("FOUND CREATION DATE");
				this.hasCreationDate = true;
				this.creationDate = new DateTime.local(int.parse(this.fullText.substring(0, 4)), 
				                                       int.parse(this.fullText.substring(5, 2)), 
				                                       int.parse(this.fullText.substring(8, 2)), 0, 0, 0);
			}
		}
	}

	public void loadCompleted() {
		// Store whether completed or not. If completed, store completed date
		if ("x " == this.fullText.substring(0, 2)) {
			this.isComplete = true;
			this.loadCompletionDate();
		} else {
			this.isComplete = false;
		}
	}

	/*
	 * TODO
	 */
	private void loadCompletionDate() {
		if (!this.isComplete) {
			return; // Just in case!
		}
	}

	/**
	 * This adds a creation date of today to the task. It's done separately from the constructor for good reason!
	 */
	public void setCreatedToday() {
		if (this.hasCreationDate) {
			// Even though this should never happen.
			return;
		}

		string newFullText;
		if (this.hasPriority()) {
			//
			newFullText = this.fullText.substring(0, 3) + " " + UserData.getYYYYMMDD() + " " + this.fullText.substring(4);
			Zystem.debug("!!!!!!!!!!!!!!!!!! " + newFullText);
			
		} else {
			newFullText = UserData.getYYYYMMDD() + " " + this.fullText;
			Zystem.debug("!!!!!!!!!!!!!!!!!! " + newFullText);
		}

		this.fullText = newFullText;

		//this.loadPriority();
		//this.loadCompleted();
		this.loadCreationDate();
		this.setDisplayText();
	}

	public void setDisplayText() {
		this.displayText = this.fullText;

		// The real deal...
		string text;

		if (this.hasCreationDate && this.hasPriority()) {
			this.displayText = this.displayText.splice(3, 14);
			//Zystem.debug("I JUST SPLICED IT? " + this.displayText);
		} else if (this.hasCreationDate && !this.hasPriority()) {
			this.displayText = this.displayText.splice(0, 11);
			//Zystem.debug("I JUST SPLICED IT? " + this.displayText);
		}
	}

	public void updateTaskText(string newText) {
		this.fullText = newText.replace("\n", "---");
		this.setDisplayText();
	}

	public bool hasPriority() {
		return this.priority != ' ';
	}

	public void setPriority(char p) {
		if (this.isComplete) {
			return; // Doing this for complete tasks is just silly.
		}
		
		// if has priority vs doesn't have priority? Handle both
		string newFullText;
		if (this.hasPriority()) {
			//
			//newFullText = this.fullText.substring(0, 3) + " " + UserData.getYYYYMMDD() + " " + this.fullText.substring(4);
			newFullText = "(" + p.to_string() + ")" + this.fullText.substring(3);
			Zystem.debug("!!!!!!!!!!!!!!!!!! " + newFullText);
			
		} else {
			newFullText = "(" + p.to_string() + ") " + this.fullText;
			Zystem.debug("!!!!!!!!!!!!!!!!!! " + newFullText);
		}

		this.fullText = newFullText;

		this.loadPriority();
		//this.loadCompleted();
		//this.loadCreationDate();
		this.setDisplayText();
	}

	public void clearPriority() {
		if (this.isComplete || !this.hasPriority()) {
			return; // Doing this for complete tasks or non-priority tasks is just silly.
		}

		this.fullText = this.fullText.substring(3);

		this.loadPriority();
		//this.loadCompleted();
		//this.loadCreationDate();
		this.setDisplayText();
	}




	public int compare_to(Task otherTask) {
		//

		//Zystem.debug("In compare_to: " + this.fullText + " vs. " + otherTask.fullText);
		//Zystem.debug(this.priority.to_string() + " vs. " + otherTask.priority.to_string());

		if (this.priority == ' ') {
			return 1;
		} else if (otherTask.priority == ' ') {
			return -1;
		} else if (this.priority > otherTask.priority) {
			return 1;
		}

		return -1;
	}

}

