task . Clean, Build, ExportHelp, Stats

task CreateManifest CopyPSD, UpdatPublicFunctionsToExport
task Build Compile, CreateManifest
task Stats RemoveStats, WriteStats

$script:ModuleName = Split-Path -Path $PSScriptRoot -Leaf
$script:ModuleRoot = $PSScriptRoot
$script:OutPutFolder = "$PSScriptRoot\Output"
$script:ImportFolders = @('Public', 'Internal')
$script:PsmPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\$($script:ModuleName).psm1"
$script:PsdPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\$($script:ModuleName).psd1"
$script:HelpPath = Join-Path -Path $PSScriptRoot -ChildPath "Output\$($script:ModuleName)\en-US"

$script:PublicFolder = 'Public'
$script:DSCResourceFolder = 'DSCResources'


task "Clean" {
    if (-not(Test-Path $script:OutPutFolder))
    {
        New-Item -ItemType Directory -Path $script:OutPutFolder > $null
    }

    Remove-Item -Path "$($script:OutPutFolder)\*" -Force -Recurse
}

$compileParams = @{
    Inputs = {
        foreach ($folder in $script:ImportFolders)
        {
            Get-ChildItem -Path $folder -Recurse -File -Filter '*.ps1'
        }
    }

    Output = {
        $script:PsmPath
    }
}

task Compile @compileParams {
    if (Test-Path -Path $script:PsmPath)
    {
        Remove-Item -Path $script:PsmPath -Recurse -Force
    }
    New-Item -Path $script:PsmPath -Force > $null

    foreach ($folder in $script:ImportFolders)
    {
        $currentFolder = Join-Path -Path $script:ModuleRoot -ChildPath $folder
        Write-Verbose -Message "Checking folder [$currentFolder]"

        if (Test-Path -Path $currentFolder)
        {
            $files = Get-ChildItem -Path $currentFolder -File -Filter '*.ps1'
            foreach ($file in $files)
            {
                Write-Verbose -Message "Adding $($file.FullName)"
                Get-Content -Path $file.FullName >> $script:PsmPath
            }
        }
    }
}

task CopyPSD {
    New-Item -Path (Split-Path $script:PsdPath) -ItemType Directory -ErrorAction 0
    $copy = @{
        Path        = "$($script:ModuleName).psd1"
        Destination = $script:PsdPath
        Force       = $true
        Verbose  = $true
    }
    Copy-Item @copy
}

task UpdatPublicFunctionsToExport -if (Test-Path -Path $script:PublicFolder) {
    $publicFunctions = (Get-ChildItem -Path $script:PublicFolder |
            Select-Object -ExpandProperty BaseName) -join "', '"

    $publicFunctions = "FunctionsToExport = @('{0}')" -f $publicFunctions

    (Get-Content -Path $script:PsdPath) -replace "FunctionsToExport = '\*'", $publicFunctions |
        Set-Content -Path $script:PsdPath
}



task ImportCompipledModule -if (Test-Path -Path $script:PsmPath) {
    Get-Module -Name $script:ModuleName |
        Remove-Module -Force
    Import-Module -Name $script:PsdPath -Force
}






task RemoveStats -if (Test-Path -Path "$($script:OutPutFolder)\stats.json") {
    Remove-Item -Force -Verbose -Path "$($script:OutPutFolder)\stats.json" 
}

task WriteStats {
    $folders = Get-ChildItem -Directory | 
        Where-Object {$PSItem.Name -ne 'Output'}
    
    $stats = foreach ($folder in $folders)
    {
        $files = Get-ChildItem "$($folder.FullName)\*" -File
        if($files)
        {
            Get-Content -Path $files | 
            Measure-Object -Word -Line -Character | 
            Select-Object -Property @{N = "FolderName"; E = {$folder.Name}}, Words, Lines, Characters
        }
    }
    $stats | ConvertTo-Json > "$script:OutPutFolder\stats.json"
}

task ExportHelp -if (Test-Path -Path "$script:ModuleRoot\Help") {
    New-ExternalHelp -Path "$script:ModuleRoot\Help" -OutputPath $script:HelpPath
}
