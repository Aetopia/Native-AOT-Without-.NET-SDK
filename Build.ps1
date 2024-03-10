param (
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$OutFile
)

if ($null -eq $(Get-Command "bflat.exe" -ErrorAction SilentlyContinue)) {
    Write-Error "[ERROR] `"bflat.exe`" is not available, check the PATH enviroment variable."
    return
}

[System.Collections.ArrayList]$ArgumentList = @("build")

$ProjectFile = Resolve-Path $Project
$ProjectPath = Split-Path $ProjectFile

$References = @{}
Get-Content "$ProjectPath\References.txt" | ForEach-Object {
    $References[$_.Trim()] = $false
}

foreach ($Item in (Get-ChildItem $ProjectPath -Recurse).FullName) {
    if ($Item -like "*.cs" -and !($Item -like "$ProjectPath\obj\*"))
    { [void]$ArgumentList.Add("`"$Item`"") }
}

$Version = ((bflat.exe -v | Out-String) -Split "+", 0, "SimpleMatch")[0].Trim()
$Lines = [array](dotnet.exe --list-sdks | Out-String) -Split "`n", 0, "SimpleMatch"
foreach ($Line in $Lines) {
    if ($Line -match '\[([^\]]+)\]' -and $Line -like "$Version*") {
        Get-ChildItem "$($Matches[1])\..\shared" -Recurse | 
        ForEach-Object { 
            if ($_ -like "*.dll" -and $References.Keys -contains $_.Name) {
                $References[$_.Name] = $true
                [void]$ArgumentList.Add("-r")
                [void]$ArgumentList.Add("`"$($_.FullName)`"")
            }
        }
    }
}

$UserProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
foreach ($Item in Get-ChildItem "$UserProfile\.nuget\packages" -Recurse) {
    if ($Item.FullName -like "*\lib\netstandard2.0\*.dll") {
        if ($References[$Item.Name]) {
            [void]$ArgumentList.Add("-r")
            [void]$ArgumentList.Add("`"$($Item.FullName)`"")
        }
    }
}

$Content = Get-Content $Project -Raw
[void]$ArgumentList.Add("--target")
[void]$ArgumentList.Add((Select-Xml -Content $Content -XPath "Project/PropertyGroup/OutputType").Node.InnerXml)
if ((Select-Xml -Content $Content -XPath "Project/PropertyGroup/Optimize").Node.InnerXml -eq "true") {
    [void]$ArgumentList.Add("--optimize-time") 
}

$LangVersion = (Select-Xml -Content $Content -XPath "Project/PropertyGroup/LangVersion" -ErrorAction SilentlyContinue).Node.InnerXml 
if ($null -ne $LangVersion) {
    [void]$ArgumentList.Add("--langversion")
    [void]$ArgumentList.Add($LangVersion);
}

[void]$ArgumentList.Add("-o")
[void]$ArgumentList.Add("`"$(Resolve-Path $OutFile)`"")

Start-Process "bflat.exe" -ArgumentList $($ArgumentList -join " ") -Wait -NoNewWindow
