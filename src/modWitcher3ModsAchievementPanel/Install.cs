// Source of install.exe (compiled together with Common.cs).
//
// It finds your Witcher 3 folder and installs this mod from the files you downloaded: it replaces any previous version in the
// mods folder. Run it from the extracted download (keep the folders of the ZIP together).
using System;
using System.IO;

internal static class InstallProgram
{
    private static int Main(string[] args)
    {
        Options options = Options.Parse(args);
        int code = 0;
        try { Run(options); }
        catch (Exception problem)
        {
            Console.WriteLine();
            Console.WriteLine("Error: " + problem.Message);
            code = 1;
        }
        Tools.Pause(options);
        return code;
    }

    private static void Run(Options options)
    {
        Console.WriteLine(Mod.Title + " installer");
        Console.WriteLine();
        string self = Tools.SelfPath();
        string source = Path.GetDirectoryName(self);
        if (!Directory.Exists(Path.Combine(source, "content")))
            throw new UserError("This is not the complete " + Mod.Title + " folder: no 'content' folder next to this file. Extract the whole ZIP first, then run this from the extracted folder.");

        string game = Tools.ResolveGameDir(options, self);
        string destination = Path.Combine(game, @"mods\" + Mod.Folder);
        bool sameFolder = Tools.SamePath(source, destination);
        // Two copies of the mod would clash, so a copy under an earlier release's folder name is removed.
        var legacy = Tools.FindLegacyFolders(game, source);

        // The config XML is next to the mod folder inside the repository layout and two folders up inside the release ZIP.
        string xmlTarget = null;
        string xmlSource = null;
        if (Mod.ConfigXml.Length > 0)
        {
            string relative = @"bin\config\r4game\user_config_matrix\pc\" + Mod.ConfigXml;
            xmlTarget = Path.Combine(game, relative);
            foreach (string candidate in new[] { Path.Combine(source, relative), Path.Combine(source, @"..\..\" + relative) })
                if (xmlSource == null && File.Exists(candidate)) xmlSource = Path.GetFullPath(candidate);
            if (xmlSource == null && !File.Exists(xmlTarget))
                throw new UserError("Could not find " + Mod.ConfigXml + " next to the mod. Extract the whole ZIP, keeping its 'bin' folder, and run this again.");
        }

        if (Tools.GameIsRunning()) throw new UserError("The Witcher 3 is running. Close the game and run this again.");

        Console.WriteLine("Game folder: " + game);
        Console.WriteLine("This will:");
        if (sameFolder) Console.WriteLine("  - keep the mod where it already is: " + destination);
        else if (Directory.Exists(destination)) Console.WriteLine("  - replace the installed mod: " + destination);
        else Console.WriteLine("  - install the mod to: " + destination);
        if (xmlSource != null) Console.WriteLine("  - copy the option definition to: " + xmlTarget);
        foreach (string old in legacy) Console.WriteLine("  - remove the former copy under its old folder name: " + old);
        if (!Tools.Confirm(options)) return;

        if (!sameFolder)
        {
            if (Directory.Exists(destination)) Tools.RemoveTree(destination, null);
            Directory.CreateDirectory(Path.GetDirectoryName(destination));
            Tools.CopyTree(source, destination);
            Console.WriteLine("Installed " + destination);
        }
        foreach (string old in legacy)
        {
            Tools.RemoveTree(old, null);
            Console.WriteLine("Removed " + old);
        }
        if (xmlSource != null)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(xmlTarget));
            File.Copy(xmlSource, xmlTarget, true);
            Console.WriteLine("Installed " + xmlTarget);
        }
        // The engine reads the config only from <game>\bin\config and ignores a bin folder inside the mod folder.
        string strayBin = Path.Combine(destination, "bin");
        if (Mod.ConfigXml.Length > 0 && Directory.Exists(strayBin)) Tools.RemoveTree(strayBin, null);

        if (!Directory.Exists(Path.Combine(destination, "content"))) throw new UserError("Installation failed: " + destination + " has no content folder.");
        if (Mod.ConfigXml.Length > 0 && !File.Exists(xmlTarget)) throw new UserError("Installation failed: " + xmlTarget + " is missing.");
        Console.WriteLine();
        Console.WriteLine(Mod.Title + " was installed.");
        Console.WriteLine("Start the game and let the scripts compile. Open Glossary > Achievements (after Crafting).");
    }
}
