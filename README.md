# Native AOT Without .NET SDK
This project showcases how one may use [`bflat`](https://github.com/bflattened/bflat) to compile Native AOT binaries without the .NET SDK.

## How does `Build.ps1` work?
`bflat` is simply a standalone compiler, so it doesn't have a build system.
> You are expected to integrate `bflat` into a build system of your choice.

`Build.ps1` attempts to provide a primitive build system for `bflat`, not perfect but gets the job done for making binaries.

`Build.ps1` resolves the following:
- Project source files.
- `OutputType`, `Optimize` & `LangVersion` properties are used and respected from the project file.
- References contained within `References.txt` are automatically resolved.

### What is `References.txt` for?
`bflat` uses the `.NET` standard library by default. 

If you want to use `NuGet` package, Windows Forms, Windows Presentation Foundation, etc.
`.NET`'s build system resolves the relevant references for you with `bflat`, you must specify them manually via the command line.

The obvious question comes to mind, "How can I find the correct references?".<br>
Determine what external references are being used in your project.<br><br>
Make sure you have the `.NET SDK` installed since this gives us access to the external assemblies as well as NuGet.<br>
If you are simply using `.NET`'s standard library, you don't need to bother with this.

In the case of the one in this repository, it is using Windows Forms.<br>
Then you will need to find the "base" assembly/reference, for Windows Forms, this is `System.Windows.Forms.dll`.<br>
Since we know what reference to use, let's add this to `References.txt`:

```
System.Windows.Forms.dll
```

When you run `Build.ps1`, it resolves any references listed in `References.txt`.<br>
It looks in 2 directories:
- The `Shared` folder in the `.NET` SDK that is compatible with `bflat`.<br>
    If you want to use things like Windows Forms or WPF with `bflat`, you must have the `.NET` SDK installed.<br>Since that contains the required assemblies.

- `%USERPROFILE\.nuget\packages`, this is where all NuGet assemblies are present.

Now running `Build.ps1` gives us the following output:
```
C:\Users\User\Documents\Projects\NativeAot\Program.cs(8,36): error CS0103: The name 'HighDpiMode' does not exist in the current context
C:\Users\User\Documents\Projects\NativeAot\Program.cs(8,9): error CS0012: The type 'HighDpiMode' is defined in an assembly that is not referenced. You must add a reference to assembly 'System.Windows.Forms.Primitives, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'.
C:\Users\User\Documents\Projects\NativeAot\MainForm.cs(9,9): error CS0012: The type 'Font' is defined in an assembly that is not referenced. You must add a reference to assembly 'System.Drawing.Common, Version=8.0.0.0, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'.
C:\Users\User\Documents\Projects\NativeAot\MainForm.cs(9,16): error CS0103: The name 'SystemFonts' does not exist in the current context
```
It's providing what references, we are missing in our project.

So it looks like this now:
```
System.Windows.Forms.dll
System.Windows.Forms.Primitives.dll
System.Drawing.Common.dll
```

Running `Build.ps1` produces some nasty output:

```
ILC: Method '[System.Windows.Forms]System.Windows.Forms.Screen.get_AllScreens()' will always throw because: Failed to load assembly 'Microsoft.Win32.SystemEvents'
ILC: Method '[System.Windows.Forms]System.Windows.Forms.ToolTip.AnnounceText(Control,string)' will always throw because: Failed to load assembly 'Accessibility'
```

It seems we are still missing some references, `bflat` lists what's missing, so lets add them:

```
System.Windows.Forms.dll
System.Windows.Forms.Primitives.dll
System.Drawing.Common.dll
Microsoft.Win32.SystemEvents.dll
Accessibility.dll
```

Running `Build.ps1` one again still produces some nasty output:

```
ILC: Trim analysis warning IL2026: System.Windows.Forms.Control.System.Windows.Forms.Layout.IArrangedElement.SetBounds(Rectangle,BoundsSpecified): Using member 'System.ComponentModel.TypeDescriptor.GetProperties(Object)' which has 'RequiresUnreferencedCodeAttribute' can break functionality when trimming application code. PropertyDescriptor's PropertyType cannot be statically discovered. The Type of component cannot be statically discovered.
ILC: Trim analysis warning IL2026: System.Windows.Forms.Control.System.Windows.Forms.Layout.IArrangedElement.SetBounds(Rectangle,BoundsSpecified): Using member 'System.ComponentModel.TypeDescriptor.GetProperties(Object)' which has 'RequiresUnreferencedCodeAttribute' can break functionality when trimming application code. PropertyDescriptor's PropertyType cannot be statically discovered. The Type of component cannot be statically discovered.
```

This is actually normal in fact, Windows Forms doesn't really play well with Native AOT or trimming.

With that aside, we have successfully compiled a Native AOT binary.

## Building
1. Install/Download the following:
    - [.NET SDK](https://dotnet.microsoft.com/en-us/download)
    - [bflat](https://github.com/bflattened/bflat/releases/latest)
2. Add `bflat.exe` to the Windows `PATH` environment variable.
3. Run the following command in PowerShell:

    ```powershell
    .\Build.ps1 -Project Native-Aot-Without-SDK.csproj -OutFile "$ENV:TEMP\Program.exe"
    ```

    This will compile and drop the compiled binary into `$ENV:TEMP`.
