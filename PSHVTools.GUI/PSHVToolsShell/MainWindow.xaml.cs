using System.Diagnostics;
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

    private void RunPowerShellCommand(string command)
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -Command \"{command}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                }
            };
            process.Start();
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();
            process.WaitForExit();

            if (process.ExitCode == 0)
            {
                MessageBox.Show("Command completed successfully!", "Success");
            }
            else
            {
                MessageBox.Show($"Command failed: {error}", "Error");
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error running command: {ex.Message}", "Error");
        }
    }

    private void BackupButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; hvbak -NamePattern \"*\" -Verbose");
    }

    private void CompactButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; hvcompact -NamePattern \"*\" -WhatIf");
    }

    private void HealthButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; hvhealth");
    }

    private void ConfigButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; Show-PSHVToolsConfig");
    }

    private void RestoreButton_Click(object sender, RoutedEventArgs e)
    {
        RunPowerShellCommand("Import-Module pshvtools; hvrecover");
    }

    private void ExitButton_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}