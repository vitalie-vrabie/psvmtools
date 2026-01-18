using System.Configuration;
using System.Data;
using System.Windows;

namespace PSHVToolsShell;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        try
        {
            var window = new MainWindow();
            window.Show();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error starting application: {ex.Message}", "Error");
            throw;
        }
    }
}

