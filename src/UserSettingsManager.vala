/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* DayTasks
 *
 * Copyright (C) Zach Burnham 2013 <thejambi@gmail.com>
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

public class UserSettingsManager : GLib.Object {

	private KeyFile keyFile;

	private string dayTasksConfPath;

	public static const string todoDirKey = "todoDirectory";
	public static const string todoDirGroup = "DayTasks";

	// Constructor
	public UserSettingsManager () {
		// Make sure the settings folder exists
		string settingsDirPath = UserData.homeDirPath + "/.config/daytasks";
		FileUtility.createFolder(settingsDirPath);

		// Get path to dayjournal.conf file
		this.dayTasksConfPath = settingsDirPath + "/daytasks.conf";

		// Make sure that settings files exist
		File settingsFile = File.new_for_path(this.dayTasksConfPath);

		if (!settingsFile.query_exists()) {
			try {
				settingsFile.create(FileCreateFlags.NONE);
			} catch(Error e) {
				stderr.printf ("Error creating settings file: %s\n", e.message);
			}
		}

		// Initialize variables
		keyFile = new KeyFile();

		try {
			keyFile.load_from_file(this.dayTasksConfPath, 0);
		} catch(Error e) {
			stderr.printf ("Error in UserSettingsManager(): %s\n", e.message);
		}

		// Process keyFile and save keyFile to disk if needed
		if (processKeyFile()) {
			this.writeKeyFile();
		}
	}

	/**
	 * Process the key file. Return true if keyFile needs to be written.
	 */
	private bool processKeyFile() {
		string originalKeyFileData = keyFile.to_data();

		try {
			UserData.todoDirPath = keyFile.get_string(this.todoDirGroup, this.todoDirKey);
		} catch (KeyFileError e) {
			// Set default
			UserData.todoDirPath = UserData.getDefaultTasksDir();
			Zystem.debug("Gotta use the default...");
		}

		// Return true if the keyFile data has been updated (if it's no longer the same as it was)
		return originalKeyFileData != keyFile.to_data();
	}

	/**
	 * Write settings file.
	 */
	private void writeKeyFile() {
		try {
			FileUtils.set_contents(this.dayTasksConfPath, this.keyFile.to_data());
		} catch(Error e) {
			stderr.printf("Error writing keyFile: %s\n", e.message);
		}
	}

	public void setTasksDir(string path) {
		keyFile.set_string(this.todoDirGroup, this.todoDirKey, path);
		writeKeyFile();
	}

	/*public void setInt(string key, int val) {
		keyFile.set_integer(this.todoDirGroup, key, val);
		writeKeyFile();
	}*/

}
