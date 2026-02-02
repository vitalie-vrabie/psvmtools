using System.Diagnostics;
using System.Threading.Tasks;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace PSHVToolsShell;

/// <summary>
/// Interaction logic for MainWindow.xaml
/// </summary>
public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private async void RunPowerShellCommand(string command)
    {
        try
        {
            var psi = new ProcessStartInfo("powershell.exe")
            {
                Arguments = $"-NoProfile -ExecutionPolicy Bypass -Command \"{command}\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            await Task.Run(() =>
            {
                using var process = Process.Start(psi);
                if (process == null)
                {
                    AppendOutput("Failed to start process.");
                    return;
                }

                process.OutputDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) AppendOutput(e.Data); };
                process.ErrorDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) AppendOutput("ERROR: " + e.Data); };

                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                process.WaitForExit();

                if (process.ExitCode == 0)
                    AppendOutput("Command completed successfully.");
                else
                    AppendOutput($"Command failed with exit code {process.ExitCode}.");
            });
        }
        catch (Exception ex)
        {
            AppendOutput("Exception: " + ex.Message);
        }
    }

    private void AppendOutput(string text)
    {
        if (string.IsNullOrEmpty(text)) return;
        Dispatcher.Invoke(() =>
        {
            OutputBox.AppendText(text + Environment.NewLine);
            OutputBox.ScrollToEnd();
        });
    }

    private void BackupButton_Click(object sender, RoutedEventArgs e)
    {
        var pattern = NamePatternBox.Text.Trim();
        var dest = DestinationBox.Text.Trim();
        var keep = KeepBox.Text.Trim();
        var comp = CompressionBox.Text.Trim();
        var whatIf = WhatIfBox.IsChecked == true ? "-WhatIf" : "";

        var cmd = $"Import-Module pshvtools; hvbak -NamePattern \"{pattern}\" -DestinationPath \"{dest}\" -Keep {keep} -CompressionLevel {comp} {whatIf} -Verbose";
        AppendOutput($"> {cmd}");
        RunPowerShellCommand(cmd);
    }

    private void CompactButton_Click(object sender, RoutedEventArgs e)
    {
        var pattern = NamePatternBox.Text.Trim();
        var whatIf = WhatIfBox.IsChecked == true ? "-WhatIf" : "";
        var cmd = $"Import-Module pshvtools; Invoke-VHDCompact -NamePattern \"{pattern}\" {whatIf}";
        AppendOutput($"> {cmd}");
        RunPowerShellCommand(cmd);
    }

    private void HealthButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; Test-PSHVToolsEnvironment");
    }

    private void ConfigButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; Get-PSHVToolsConfig | Format-List * -Force");
    }

    private void RestoreButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; Restore-OrphanedVMs");
    }

    private void ExitButton_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}