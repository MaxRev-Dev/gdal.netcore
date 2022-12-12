
using System;
using System.IO;
using System.Linq;

namespace GdalCore_XUnit
{
    public class Extensions
    {
        public static string GetTestDataFolder(string testDataFolder)
        {
            var startupPath = AppContext.BaseDirectory;
            var pathItems = startupPath.Split(Path.DirectorySeparatorChar);
            var pos = pathItems.Reverse().ToList().FindIndex(x => string.Equals("bin", x));
            var projectPath = string.Join(Path.DirectorySeparatorChar.ToString(),
                pathItems.Take(pathItems.Length - pos - 1));
            return Path.Combine(projectPath, testDataFolder);
        }
    }
}