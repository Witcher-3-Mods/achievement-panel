// Shared by install.exe and uninstall.exe. tools/Build-Witcher3ModsInstallers.ps1 compiles Common.cs together with Install.cs
// (install.exe) or Uninstall.cs (uninstall.exe) using the C# compiler that ships with Windows. The release ZIP carries only the
// .exe files; these sources stay in the repository. Nothing here runs PowerShell or any other program.
//
// Switches both programs understand (used by the maintainers for testing):
//   /yes                 do not ask for confirmation
//   /game:"C:\path"      use this game folder instead of searching
//   /docs:"C:\path"      use this folder instead of Documents\The Witcher 3 (uninstall.exe only)
//   /removeself          uninstall.exe only: also delete uninstall.exe and its folder when it is done, without asking
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;
using Microsoft.Win32;

// ---- What this installer puts where. Everything else is left alone. ---------------------------------------------------
internal static class Mod
{
    public const string Folder = "modWitcher3ModsAchievementPanel";   // <game>\mods\<this folder>
    public const string Title = "Achievement Panel";
    public static readonly string ConfigXml = "";                     // <game>\bin\config\r4game\user_config_matrix\pc\<this file> (empty: none)
    public static readonly string[] Sections = { "Witcher3ModsAchievementPanel" };   // whole sections in the *user.settings files
    public static readonly string[][] Keys = new string[0][];         // { section, key } pairs: single keys in other sections
    public const string LegacyFolderPattern = "modWitcher3ModsAch*Panel";   // earlier releases used a misspelled folder name
}

// A problem the user can act on: shown as "Error: <message>" without a stack trace.
internal sealed class UserError : Exception
{
    public UserError(string message) : base(message) { }
}

internal sealed class Options
{
    public bool Yes;
    public bool RemoveSelf;
    public string Game;
    public string Docs;

    public static Options Parse(string[] args)
    {
        Options options = new Options();
        foreach (string raw in args)
        {
            string arg = raw.Trim();
            if (arg.Equals("/yes", StringComparison.OrdinalIgnoreCase)) options.Yes = true;
            else if (arg.Equals("/removeself", StringComparison.OrdinalIgnoreCase)) options.RemoveSelf = true;
            else if (arg.StartsWith("/game:", StringComparison.OrdinalIgnoreCase)) options.Game = arg.Substring(6).Trim('"');
            else if (arg.StartsWith("/docs:", StringComparison.OrdinalIgnoreCase)) options.Docs = arg.Substring(6).Trim('"');
        }
        return options;
    }
}

internal static class Tools
{
    public static string SelfPath()
    {
        return Assembly.GetExecutingAssembly().Location;
    }

    public static string Normalize(string path)
    {
        return Path.GetFullPath(path).TrimEnd('\\');
    }

    public static bool SamePath(string a, string b)
    {
        return string.Equals(Normalize(a), Normalize(b), StringComparison.OrdinalIgnoreCase);
    }

    // Returns what the user typed, or null when there is no console input (it was closed or redirected).
    public static string Ask(string prompt)
    {
        Console.Write(prompt + ": ");
        return Console.ReadLine();
    }

    public static bool Confirm(Options options)
    {
        if (options.Yes) return true;
        string answer = Ask("Continue? [Y/n]");
        if (answer != null && Regex.IsMatch(answer, @"^\s*n", RegexOptions.IgnoreCase))
        {
            Console.WriteLine("Cancelled. Nothing was changed.");
            return false;
        }
        return true;
    }

    public static void Pause(Options options)
    {
        if (!options.Yes) Ask("Press Enter to close");
    }

    public static bool IsGameDir(string path)
    {
        return !string.IsNullOrEmpty(path)
            && Directory.Exists(Path.Combine(path, @"bin\config\r4game"))
            && Directory.Exists(Path.Combine(path, @"content\content0"));
    }

    // The Steam registry value is lowercase with forward slashes ("c:/program files (x86)/steam"), while the drive scan below
    // uses the usual capitalised folders. Both name the same folder, so the same game was listed twice. Rewrite every path
    // with the casing stored on disk before comparing.
    private static string DiskCasePath(string path)
    {
        string full = Normalize(path);
        try
        {
            string root = Path.GetPathRoot(full);
            string result = root.ToUpperInvariant();
            foreach (string part in full.Substring(root.Length).Split('\\'))
            {
                if (part.Length == 0) continue;
                string[] entry = Directory.GetFileSystemEntries(result, part);
                if (entry.Length == 0) return full;
                result = entry[0];
            }
            return result;
        }
        catch (Exception) { return full; }
    }

    private static string RegistryText(RegistryKey key, string name)
    {
        object value = key == null ? null : key.GetValue(name);
        return value == null ? null : value.ToString();
    }

    // Looks in the places a Witcher 3 install usually is: Steam libraries, GOG, Epic and the usual folders on every fixed drive.
    public static List<string> FindGameDirs()
    {
        List<string> found = new List<string>();
        List<string> steamRoots = new List<string>();
        try
        {
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam"))
            {
                steamRoots.Add(RegistryText(key, "SteamPath"));
                steamRoots.Add(RegistryText(key, "InstallPath"));
            }
            using (RegistryKey hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32))
            using (RegistryKey key = hklm.OpenSubKey(@"SOFTWARE\Valve\Steam"))
            {
                steamRoots.Add(RegistryText(key, "SteamPath"));
                steamRoots.Add(RegistryText(key, "InstallPath"));
            }
        }
        catch (Exception) { }

        string[] folders = { "The Witcher 3", "The Witcher 3 Wild Hunt" };
        List<string> seenRoots = new List<string>();
        foreach (string root in steamRoots)
        {
            if (string.IsNullOrEmpty(root) || seenRoots.Contains(root)) continue;
            seenRoots.Add(root);
            List<string> libraries = new List<string>();
            libraries.Add(root);
            try
            {
                string vdf = Path.Combine(root, @"steamapps\libraryfolders.vdf");
                if (File.Exists(vdf))
                    foreach (Match m in Regex.Matches(File.ReadAllText(vdf), "\"path\"\\s+\"([^\"]+)\""))
                        libraries.Add(m.Groups[1].Value.Replace(@"\\", @"\"));
            }
            catch (Exception) { }
            foreach (string library in libraries)
                foreach (string folder in folders)
                    found.Add(Path.Combine(library, @"steamapps\common\" + folder));
        }

        try
        {
            using (RegistryKey hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32))
                foreach (string id in new[] { "1495134320", "1207664643" })
                    using (RegistryKey key = hklm.OpenSubKey(@"SOFTWARE\GOG.com\Games\" + id))
                    {
                        string gog = RegistryText(key, "path");
                        if (!string.IsNullOrEmpty(gog)) found.Add(gog);
                    }
        }
        catch (Exception) { }

        string[] usual =
        {
            @"Program Files (x86)\Steam\steamapps\common\The Witcher 3", @"SteamLibrary\steamapps\common\The Witcher 3",
            @"Steam\steamapps\common\The Witcher 3", @"Games\Steam\steamapps\common\The Witcher 3",
            @"GOG Games\The Witcher 3 Wild Hunt GOTY", @"GOG Games\The Witcher 3 Wild Hunt",
            @"Program Files (x86)\GOG Galaxy\Games\The Witcher 3 Wild Hunt GOTY", @"Program Files (x86)\GOG Galaxy\Games\The Witcher 3 Wild Hunt",
            @"Program Files\Epic Games\TheWitcher3", @"Epic Games\TheWitcher3", @"Games\The Witcher 3"
        };
        foreach (DriveInfo drive in DriveInfo.GetDrives())
        {
            if (drive.DriveType != DriveType.Fixed || !drive.IsReady) continue;
            foreach (string relative in usual) found.Add(Path.Combine(drive.RootDirectory.FullName, relative));
        }

        List<string> result = new List<string>();
        foreach (string candidate in found)
        {
            if (!IsGameDir(candidate)) continue;
            string path = DiskCasePath(candidate);
            if (!result.Contains(path)) result.Add(path);
        }
        result.Sort(StringComparer.OrdinalIgnoreCase);
        return result;
    }

    public static string ResolveGameDir(Options options, string self)
    {
        if (!string.IsNullOrEmpty(options.Game))
        {
            if (!IsGameDir(options.Game)) throw new UserError("Not a Witcher 3 folder: " + options.Game);
            return Normalize(options.Game);
        }
        // Run from <game>\mods\<mod>: that game is the one to use, no searching needed.
        string modsDir = Path.GetDirectoryName(Path.GetDirectoryName(self));
        if (modsDir != null && string.Equals(Path.GetFileName(modsDir), "mods", StringComparison.OrdinalIgnoreCase))
        {
            string here = Path.GetDirectoryName(modsDir);
            if (IsGameDir(here))
            {
                here = Normalize(here);
                Console.WriteLine("Using the game folder this mod is in: " + here);
                return here;
            }
        }
        List<string> candidates = FindGameDirs();
        if (candidates.Count == 1) { Console.WriteLine("Found The Witcher 3: " + candidates[0]); return candidates[0]; }
        if (options.Yes) throw new UserError("Could not decide which game folder to use. Pass /game:\"C:\\path\\to\\The Witcher 3\".");
        while (true)
        {
            string answer;
            if (candidates.Count > 1)
            {
                Console.WriteLine("Found several Witcher 3 folders:");
                for (int i = 0; i < candidates.Count; i++) Console.WriteLine("  " + (i + 1) + ") " + candidates[i]);
                answer = Ask("Type a number, or paste the full path of the game folder");
            }
            else
            {
                Console.WriteLine("Could not find The Witcher 3 in the usual places.");
                answer = Ask("Paste the full path of the game folder (the one that contains bin, content and mods)");
            }
            if (answer == null) throw new UserError("No game folder was given.");
            answer = answer.Trim().Trim('"');
            int number;
            if (int.TryParse(answer, out number) && number >= 1 && number <= candidates.Count) return candidates[number - 1];
            if (IsGameDir(answer)) return Normalize(answer);
            Console.WriteLine("That is not a Witcher 3 folder: " + answer);
        }
    }

    // Deletes a folder tree without ever following a junction or symbolic link: a link is detached (only the link is deleted),
    // everything else is deleted normally. A file named by 'keep' (the running program itself, which Windows will not let
    // anything delete) is left in place; the result says whether everything was removed.
    public static bool RemoveTree(string path, string keep)
    {
        FileAttributes attributes = File.GetAttributes(path);
        bool isDirectory = (attributes & FileAttributes.Directory) != 0;
        if ((attributes & FileAttributes.ReparsePoint) != 0)
        {
            if (isDirectory) Directory.Delete(path); else File.Delete(path);
            return true;
        }
        if (!isDirectory)
        {
            if (keep != null && SamePath(path, keep)) return false;
            File.SetAttributes(path, FileAttributes.Normal);
            File.Delete(path);
            return true;
        }
        bool all = true;
        foreach (string child in Directory.GetFileSystemEntries(path))
            if (!RemoveTree(child, keep)) all = false;
        if (!all) return false;
        File.SetAttributes(path, FileAttributes.Normal);
        Directory.Delete(path);
        return true;
    }

    public static void CopyTree(string source, string destination)
    {
        Directory.CreateDirectory(destination);
        // A symbolic link or junction is skipped, never followed: File.Copy would copy what a file link points to.
        foreach (string file in Directory.GetFiles(source))
        {
            if ((File.GetAttributes(file) & FileAttributes.ReparsePoint) != 0) continue;
            File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), true);
        }
        foreach (string directory in Directory.GetDirectories(source))
        {
            if ((File.GetAttributes(directory) & FileAttributes.ReparsePoint) != 0) continue;
            CopyTree(directory, Path.Combine(destination, Path.GetFileName(directory)));
        }
    }

    // True when a path can be put inside double quotes on a cmd.exe command line and stay plain text. cmd expands %NAME% even
    // inside quotes, and ^, & and ! are special in other contexts, so a path with any of them is not passed to cmd at all.
    public static bool IsSafeForCmd(string path)
    {
        return path.IndexOfAny(new[] { '%', '^', '&', '!', '"', '\r', '\n' }) < 0;
    }

    // Copies of the mod's folder under the name earlier releases used, other than 'except'.
    public static List<string> FindLegacyFolders(string game, params string[] except)
    {
        List<string> legacy = new List<string>();
        string mods = Path.Combine(game, "mods");
        if (!Directory.Exists(mods)) return legacy;
        foreach (string directory in Directory.GetDirectories(mods, Mod.LegacyFolderPattern))
        {
            bool skip = string.Equals(Path.GetFileName(directory), Mod.Folder, StringComparison.OrdinalIgnoreCase);
            foreach (string other in except) if (other != null && SamePath(directory, other)) skip = true;
            if (!skip) legacy.Add(directory);
        }
        return legacy;
    }

    public static bool GameIsRunning()
    {
        return System.Diagnostics.Process.GetProcessesByName("witcher3").Length > 0;
    }
}
