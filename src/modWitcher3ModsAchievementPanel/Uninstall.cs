// Source of uninstall.exe (compiled together with Common.cs).
//
// It finds your Witcher 3 folder, then removes this mod and only this mod: its folder under mods, and its own section in the
// game's *user.settings files (a copy of each changed file is kept next to it as *.bak-uninstall-*). Other mods and the rest
// of your settings are not touched.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

internal static class UninstallProgram
{
    private static int Main(string[] args)
    {
        Options options = Options.Parse(args);
        int code = 0;
        string folderToRemove = null;
        try { folderToRemove = Run(options); }
        catch (Exception problem)
        {
            Console.WriteLine();
            Console.WriteLine("Error: " + problem.Message);
            code = 1;
        }
        if (folderToRemove != null && StartSelfRemoval(folderToRemove)) return code;
        Tools.Pause(options);
        return code;
    }

    // Windows will not delete a program while it runs, so the last step is a short background command that waits a moment for
    // this program to exit and then deletes uninstall.exe and its (by then empty) folder.
    private static bool StartSelfRemoval(string folder)
    {
        try
        {
            // The full path of cmd.exe: a bare name would be searched for in this program's own folder first.
            ProcessStartInfo start = new ProcessStartInfo(Path.Combine(Environment.SystemDirectory, "cmd.exe"));
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            start.Arguments = "/d /c \"ping -n 3 127.0.0.1 >nul & del /f /q \"" + Tools.SelfPath() + "\" & rmdir \"" + folder + "\"\"";
            Process.Start(start);
            return true;
        }
        catch (Exception problem)
        {
            Console.WriteLine("Could not remove uninstall.exe automatically: " + problem.Message);
            Console.WriteLine("You can delete the folder yourself: " + folder);
            return false;
        }
    }

    // After everything else is gone, a running uninstall.exe in the mod folder is all that is left. Asks what to do about it.
    // Returns true when the user wants the program to remove itself too.
    private static bool AskAboutLeftover(Options options, string modDir)
    {
        // The paths go into a cmd.exe command line; if they contain a character cmd treats specially, option 2 is not offered.
        if (!Tools.IsSafeForCmd(Tools.SelfPath()) || !Tools.IsSafeForCmd(modDir))
        {
            Console.WriteLine();
            Console.WriteLine("Only uninstall.exe is left in " + modDir + ".");
            Console.WriteLine("Its path contains a special character (one of % ^ & !), so it cannot be removed automatically.");
            return false;
        }
        if (options.RemoveSelf) return true;
        if (options.Yes) return false;
        Console.WriteLine();
        Console.WriteLine("Only uninstall.exe is left in " + modDir + ".");
        Console.WriteLine("Windows cannot delete a program while it is running. How would you like to finish?");
        Console.WriteLine();
        Console.WriteLine("  1) I will delete the folder myself");
        Console.WriteLine("     Nothing else happens. Close this window and delete the folder when you like.");
        Console.WriteLine("  2) Remove everything, including this program");
        Console.WriteLine("     A short background command deletes uninstall.exe and its folder right after this window");
        Console.WriteLine("     closes. Some antivirus programs may warn about a program that deletes itself.");
        Console.WriteLine();
        while (true)
        {
            string answer = Tools.Ask("Type 1 or 2");
            if (answer == null) return false;
            answer = answer.Trim();
            if (answer == "1") return false;
            if (answer == "2") return true;
            Console.WriteLine("Please type 1 or 2.");
        }
    }

    // Returns the folder that should be deleted after this program exits, or null when there is nothing left to delete.
    private static string Run(Options options)
    {
        Console.WriteLine(Mod.Title + " uninstaller");
        Console.WriteLine();
        string self = Tools.SelfPath();
        string game = Tools.ResolveGameDir(options, self);
        string docs = options.Docs;
        if (string.IsNullOrEmpty(docs))
            docs = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "The Witcher 3");

        string modDir = Path.Combine(game, @"mods\" + Mod.Folder);
        List<string> legacy = Tools.FindLegacyFolders(game);
        string xmlPath = null;
        if (Mod.ConfigXml.Length > 0) xmlPath = Path.Combine(game, @"bin\config\r4game\user_config_matrix\pc\" + Mod.ConfigXml);
        List<string> settings = new List<string>();
        foreach (string name in new[] { "user.settings", "dx11user.settings", "dx12user.settings" })
        {
            string path = Path.Combine(docs, name);
            if (File.Exists(path) && EditSettings(path, false) > 0) settings.Add(path);
        }

        List<string> present = new List<string>();
        if (Directory.Exists(modDir)) present.Add("Mod folder:        " + modDir);
        foreach (string old in legacy) present.Add("Former mod folder: " + old);
        if (xmlPath != null && File.Exists(xmlPath)) present.Add("Option definition: " + xmlPath);
        foreach (string path in settings) present.Add("Saved option value: " + path + " (the mod's section only)");
        if (present.Count == 0)
        {
            Console.WriteLine(Mod.Title + " is not installed in " + game + ". Nothing to remove.");
            return null;
        }
        if (Tools.GameIsRunning()) throw new UserError("The Witcher 3 is running. Close the game and run this again.");
        Console.WriteLine("Game folder: " + game);
        Console.WriteLine("This will remove:");
        foreach (string line in present) Console.WriteLine("  " + line);
        Console.WriteLine("Other mods and the rest of your settings are not touched.");
        if (!Tools.Confirm(options)) return null;

        // Started from the mod folder (double-clicked there), this program's working directory is that folder, and Windows
        // will not delete a folder that is some process's working directory. Step out of it first.
        Environment.CurrentDirectory = Path.GetTempPath();

        // Windows will not delete a program while it runs, so a running uninstall.exe that lives in the mod folder is the one
        // thing left behind; everything else in the folder is removed.
        bool leftover = false;
        if (Directory.Exists(modDir))
        {
            if (Tools.RemoveTree(modDir, self)) Console.WriteLine("Removed " + modDir);
            else { leftover = true; Console.WriteLine("Removed everything in " + modDir + " except this uninstall.exe"); }
        }
        foreach (string old in legacy)
        {
            Tools.RemoveTree(old, self);
            Console.WriteLine("Removed " + old);
        }
        if (xmlPath != null && File.Exists(xmlPath))
        {
            File.Delete(xmlPath);
            Console.WriteLine("Removed " + xmlPath);
        }
        foreach (string path in settings)
        {
            int removed = EditSettings(path, true);
            Console.WriteLine("Removed " + removed + " line(s) from " + path + " (a copy is next to it: *.bak-uninstall-*)");
        }
        Console.WriteLine();
        Console.WriteLine(Mod.Title + " was uninstalled.");
        if (!leftover) return null;
        if (AskAboutLeftover(options, modDir))
        {
            Console.WriteLine();
            Console.WriteLine("Removing uninstall.exe and its folder. This window will close by itself.");
            return modDir;
        }
        Console.WriteLine();
        Console.WriteLine("All done. You can delete this folder now: " + modDir);
        return null;
    }

    // Settings files are edited as raw bytes (Latin-1 round-trips every byte), so nothing but the mod's own lines changes.
    // Returns how many lines belong to the mod; with apply, those lines are removed after a backup copy is made.
    private static int EditSettings(string file, bool apply)
    {
        Encoding latin1 = Encoding.GetEncoding(28591);
        string[] lines = Regex.Split(latin1.GetString(File.ReadAllBytes(file)), "(?<=\n)");
        StringBuilder kept = new StringBuilder();
        string section = "";
        int removed = 0;
        foreach (string line in lines)
        {
            Match header = Regex.Match(line, @"^\s*\[([^\]\r\n]+)\]\s*$");
            if (header.Success) section = header.Groups[1].Value;
            bool drop = Array.Exists(Mod.Sections, s => string.Equals(s, section, StringComparison.OrdinalIgnoreCase));
            if (!drop)
                foreach (string[] key in Mod.Keys)
                    if (string.Equals(section, key[0], StringComparison.OrdinalIgnoreCase)
                        && Regex.IsMatch(line, @"^\s*" + Regex.Escape(key[1]) + @"\s*=", RegexOptions.IgnoreCase))
                        drop = true;
            if (drop) removed++; else kept.Append(line);
        }
        if (apply && removed > 0)
        {
            File.Copy(file, file + ".bak-uninstall-" + DateTime.Now.ToString("yyyyMMdd-HHmmss"));
            File.WriteAllBytes(file, latin1.GetBytes(kept.ToString()));
        }
        return removed;
    }
}
