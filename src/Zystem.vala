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

/**
 * This class is for random helpful methods.
 */
class Zystem : GLib.Object {

	public static bool debugOn { get; set; default = false; }
	
	/**
	 * My own println method. Hey, I'm a Java programmer!
	 */
	public static void println(string s){
		stdout.printf(s + "\n");
	}

	/**
	 * Debug method. Only prints if debug is set on.
	 */
	public static void debug(string s) {
		if (debugOn) {
			stdout.printf(s + "\n");
		}
	}

	/**
	 * 
	 */
	public static void debugFileInfo(FileInfo file) {
		debug("File type: " + file.get_file_type().to_string());
	}

	
}