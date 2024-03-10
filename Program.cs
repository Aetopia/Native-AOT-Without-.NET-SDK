using System.Windows.Forms;

class Program
{
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        new MainForm().ShowDialog();
    }
}