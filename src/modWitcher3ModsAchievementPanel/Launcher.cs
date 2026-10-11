// Source of install.exe and uninstall.exe. Both are built from this one file by tools/Build-Witcher3ModsInstallers.ps1,
// each with its own script (install.ps1 or uninstall.ps1) embedded as the resource "script.ps1". The script next to
// the .exe is the readable copy of what the .exe runs; the .exe does nothing else.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

internal static class Launcher
{
    private static int Main()
    {
        string self = Assembly.GetExecutingAssembly().Location;
        string tempScript = Path.Combine(Path.GetTempPath(), "w3m-" + Guid.NewGuid().ToString("N") + ".ps1");
        try
        {
            using (Stream resource = Assembly.GetExecutingAssembly().GetManifestResourceStream("script.ps1"))
            {
                if (resource == null) throw new InvalidOperationException("The embedded script is missing.");
                using (StreamReader reader = new StreamReader(resource, Encoding.UTF8))
                    // UTF-8 with a byte order mark, so Windows PowerShell 5.1 reads the file as UTF-8.
                    File.WriteAllText(tempScript, reader.ReadToEnd(), new UTF8Encoding(true));
            }
        }
        catch (Exception problem)
        {
            Console.Error.WriteLine("Could not prepare the installer script: " + problem.Message);
            return 1;
        }

        // The script receives this file's path and the command line exactly as typed, like %~f0 and %* in a batch file.
        ProcessStartInfo start = new ProcessStartInfo("powershell.exe");
        start.UseShellExecute = false;
        start.EnvironmentVariables["W3M_SELF"] = self;
        start.EnvironmentVariables["W3M_ARGS"] = RawArguments();
        // The wrapper deletes the temporary copy afterwards and keeps the script's exit code.
        start.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"& '" + tempScript.Replace("'", "''")
            + "'; $code = $LASTEXITCODE; Remove-Item -LiteralPath '" + tempScript.Replace("'", "''")
            + "' -Force -ErrorAction SilentlyContinue; exit $code\"";

        Process script;
        try { script = Process.Start(start); }
        catch (Exception problem)
        {
            Console.Error.WriteLine("Could not start PowerShell: " + problem.Message);
            try { File.Delete(tempScript); } catch { }
            return 1;
        }

        // Run from <game>\mods\<mod folder>, the uninstaller deletes the folder this file is in. Windows will not delete
        // a running .exe, so in that location hand over to PowerShell (which keeps the console) and exit at once.
        if (IsInsideModsFolder(self)) return 0;
        script.WaitForExit();
        return script.ExitCode;
    }

    // Everything after the program name, with the user's own quoting, as a batch file's %* would hold it.
    private static string RawArguments()
    {
        string line = Environment.CommandLine;
        int end;
        if (line.StartsWith("\""))
        {
            end = line.IndexOf('"', 1);
            end = end < 0 ? line.Length : end + 1;
        }
        else
        {
            end = line.IndexOf(' ');
            if (end < 0) end = line.Length;
        }
        return line.Substring(end).Trim();
    }

    private static bool IsInsideModsFolder(string self)
    {
        string modFolder = Path.GetDirectoryName(self);
        string mods = modFolder == null ? null : Path.GetDirectoryName(modFolder);
        return mods != null && string.Equals(Path.GetFileName(mods), "mods", StringComparison.OrdinalIgnoreCase);
    }
}
