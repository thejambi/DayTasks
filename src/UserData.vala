/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/* DayTasks
 *
 * Copyright (C) 2012 Zach Burnham <thejambi@gmail.com>
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
using GLib;

class UserData : Object {
	
	public static string defaultTasksDirName { get; private set; }
	
	public static string tasksDirPath { get; private set; }

	public static string todoDirPath { get; set; }
//	public static string todoFilePath { get; private set; }
	
	public static string homeDirPath { get; private set; }

	public static int windowWidth { get; set; default = 460; }
	public static int windowHeight { get; set; default = 480; }

	private static UserSettingsManager settings;

	/**
	 * Initialize everything in UserData.
	 */
	public static void initializeUserData() {
		
		homeDirPath = Environment.get_home_dir();

		defaultTasksDirName = "todo";

		settings = new UserSettingsManager();
		// Load data from user's config file
		

		// Create Todo Directory
		//FileUtility.createFolder(tasksDirPath);
	}

	/*public static void setTodoFilePath(string path) {
		todoFilePath = path;
		// Process new file...
	}*/

	public static void setTasksDir(string path) {
		todoDirPath = path;
		settings.setTasksDir(path);
	}

	public static string getTodoFilePath() {
		Zystem.debug("Todo.txt path is: " + FileUtility.pathCombine(todoDirPath, "todo.txt"));
		return FileUtility.pathCombine(todoDirPath, "todo.txt");
	}

	public static string getDefaultTasksDir() {
		// If Dropbox/todo/ exists, use it. If not, well then just don't.
		string dropboxTodo = FileUtility.pathCombine(homeDirPath, "Dropbox");
		dropboxTodo = FileUtility.pathCombine(dropboxTodo, defaultTasksDirName);

		File dropboxFile = File.new_for_path(dropboxTodo);
		if (dropboxFile.query_exists()) {
			return dropboxTodo;
		} else {
			return FileUtility.pathCombine(homeDirPath, defaultTasksDirName);
		}
	}

	public static string getDefaultTodoFilePath() {
		Zystem.debug("Default todo file path is:");
		Zystem.debug(FileUtility.pathCombine(getDefaultTasksDir(), "todo.txt"));
		return FileUtility.pathCombine(getDefaultTasksDir(), "todo.txt");
	}

	/*
	public static void saveWindowSize(int width, int height) {
		Zystem.debug(width.to_string() + " and the height: " + height.to_string());
		settings.setInt(UserSettingsManager.windowWidthKey, width);
		settings.setInt(UserSettingsManager.windowHeightKey, height);
	}

	public static void savePanePosition(int position) {
		settings.setInt(UserSettingsManager.panePositionKey, position);
	}
	*/

	
	
}
