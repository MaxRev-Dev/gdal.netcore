using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;

namespace MaxRev.Gdal.CLI
{
    public static class GdalCli
    {
        public static void EnsureEnvironment()
        {
            PathInitializer.Initialize();
        }

        public static string? GetToolPath(string toolName, string? baseDir = null)
        {
            if (string.IsNullOrWhiteSpace(toolName))
            {
                return null;
            }

            baseDir = string.IsNullOrWhiteSpace(baseDir) ? AppContext.BaseDirectory : baseDir;
            var exeName = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) && !toolName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)
                ? toolName + ".exe"
                : toolName;

            var direct = Path.Combine(baseDir, exeName);
            if (File.Exists(direct))
            {
                return direct;
            }

            var rid = GetRuntimeRid();
            if (string.IsNullOrEmpty(rid))
            {
                return null;
            }

            var toolPath = Path.Combine(baseDir, "tools", rid, exeName);
            return File.Exists(toolPath) ? toolPath : null;
        }

        public static IReadOnlyList<string> GetAvailableTools(string? baseDir = null)
        {
            baseDir = string.IsNullOrWhiteSpace(baseDir) ? AppContext.BaseDirectory : baseDir;
            var isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows);
            var tools = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            CollectTools(baseDir, isWindows, tools);

            var rid = GetRuntimeRid();
            if (!string.IsNullOrEmpty(rid))
            {
                var toolsDir = Path.Combine(baseDir, "tools", rid);
                CollectTools(toolsDir, isWindows, tools);
            }

            var result = tools.ToList();
            result.Sort(StringComparer.OrdinalIgnoreCase);
            return result;
        }

        private static void CollectTools(string directory, bool isWindows, HashSet<string> tools)
        {
            if (!Directory.Exists(directory))
            {
                return;
            }

            foreach (var file in Directory.GetFiles(directory))
            {
                var fileName = Path.GetFileName(file);
                if (isWindows)
                {
                    if (!fileName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                }
                else
                {
                    if (fileName.Contains('.'))
                    {
                        continue;
                    }
                }

                var name = Path.GetFileNameWithoutExtension(file);
                if (!string.IsNullOrEmpty(name))
                {
                    tools.Add(name);
                }
            }
        }

        public static int Run(string toolName,
            IEnumerable<string>? args = null,
            string? workingDirectory = null,
            Action<string>? stdout = null,
            Action<string>? stderr = null)
        {
            EnsureEnvironment();

            var toolPath = GetToolPath(toolName);
            if (string.IsNullOrEmpty(toolPath))
            {
                throw new FileNotFoundException($"Tool '{toolName}' not found.");
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = toolPath,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            };

            if (!string.IsNullOrWhiteSpace(workingDirectory))
            {
                startInfo.WorkingDirectory = workingDirectory;
            }

            if (args != null)
            {
                startInfo.Arguments = string.Join(" ", EscapeArgs(args));
            }

            using var process = Process.Start(startInfo);
            if (process == null)
            {
                throw new InvalidOperationException("Failed to start CLI tool.");
            }

            // Read both streams concurrently to avoid a deadlock when one pipe buffer
            // fills while we are blocked reading the other (mirrors RunAsync).
            var outputTask = process.StandardOutput.ReadToEndAsync();
            var errorTask = process.StandardError.ReadToEndAsync();
            process.WaitForExit();

            var output = outputTask.GetAwaiter().GetResult();
            var error = errorTask.GetAwaiter().GetResult();

            if (!string.IsNullOrWhiteSpace(output))
            {
                stdout?.Invoke(output);
            }

            if (!string.IsNullOrWhiteSpace(error))
            {
                stderr?.Invoke(error);
            }

            return process.ExitCode;
        }

        /// <summary>
        /// Asynchronously runs the given CLI tool and returns its exit code.
        /// stdout and stderr are read concurrently and reported via the optional callbacks.
        /// If <paramref name="cancellationToken"/> is cancelled, the tool is terminated and
        /// an <see cref="OperationCanceledException"/> is thrown.
        /// </summary>
        public static async Task<int> RunAsync(string toolName,
            IEnumerable<string>? args = null,
            string? workingDirectory = null,
            Action<string>? stdout = null,
            Action<string>? stderr = null,
            CancellationToken cancellationToken = default)
        {
            EnsureEnvironment();

            var toolPath = GetToolPath(toolName);
            if (string.IsNullOrEmpty(toolPath))
            {
                throw new FileNotFoundException($"Tool '{toolName}' not found.");
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = toolPath,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            };

            if (!string.IsNullOrWhiteSpace(workingDirectory))
            {
                startInfo.WorkingDirectory = workingDirectory;
            }

            if (args != null)
            {
                startInfo.Arguments = string.Join(" ", EscapeArgs(args));
            }

            using var process = Process.Start(startInfo);
            if (process == null)
            {
                throw new InvalidOperationException("Failed to start CLI tool.");
            }

            // Read both streams concurrently to avoid a deadlock when one pipe
            // buffer fills while we are blocked reading the other.
            var outputTask = process.StandardOutput.ReadToEndAsync();
            var errorTask = process.StandardError.ReadToEndAsync();

            try
            {
                await WaitForExitAsync(process, cancellationToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                // Terminate the tool so its redirected streams close, then observe the
                // pending reads (so they do not fault unobserved) before rethrowing.
                TryKill(process);
                try { await Task.WhenAll(outputTask, errorTask).ConfigureAwait(false); }
                catch { /* ignored - surfacing the cancellation below */ }
                throw;
            }

            var output = await outputTask.ConfigureAwait(false);
            var error = await errorTask.ConfigureAwait(false);

            if (!string.IsNullOrWhiteSpace(output))
            {
                stdout?.Invoke(output);
            }

            if (!string.IsNullOrWhiteSpace(error))
            {
                stderr?.Invoke(error);
            }

            return process.ExitCode;
        }

        private static void TryKill(Process process)
        {
            try
            {
                if (!process.HasExited)
                {
                    process.Kill();
                }
            }
            catch
            {
                // process may have already exited
            }
        }

#if NET5_0_OR_GREATER
        private static Task WaitForExitAsync(Process process, CancellationToken cancellationToken)
            => process.WaitForExitAsync(cancellationToken);
#else
        private static async Task WaitForExitAsync(Process process, CancellationToken cancellationToken)
        {
            if (process.HasExited)
            {
                return;
            }

            var tcs = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnExited(object? sender, EventArgs e) => tcs.TrySetResult(true);

            process.EnableRaisingEvents = true;
            process.Exited += OnExited;
            try
            {
                // Re-check in case the process exited before the handler was attached.
                if (process.HasExited)
                {
                    return;
                }

                using (cancellationToken.Register(() => tcs.TrySetCanceled(cancellationToken)))
                {
                    await tcs.Task.ConfigureAwait(false);
                }
            }
            finally
            {
                process.Exited -= OnExited;
            }
        }
#endif

        private static IEnumerable<string> EscapeArgs(IEnumerable<string> args)
        {
            foreach (var arg in args)
            {
                if (string.IsNullOrEmpty(arg))
                {
                    yield return "\"\"";
                }
                else if (arg.IndexOfAny(new[] { ' ', '\t', '\n', '"' }) >= 0)
                {
                    yield return "\"" + arg.Replace("\"", "\\\"") + "\"";
                }
                else
                {
                    yield return arg;
                }
            }
        }

        private static string? GetRuntimeRid()
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                return RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "osx-arm64" : "osx-x64";
            }

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                return RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "linux-arm64" : "linux-x64";
            }

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                return "win-x64";
            }

            return null;
        }
    }
}
