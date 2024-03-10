using System.Drawing;
using System.Windows.Forms;

class MainForm : Form
{
    public MainForm()
    {
        Text = "Hello World!";
        Font = SystemFonts.MessageBoxFont;
        Controls.Add(new Button
        {
            Text = "Hello World!",
            Dock = DockStyle.Fill
        });
    }
}