Function Add-BackSlashToPath ($Path){
<#
    .SYNOPSIS
    Add a backslash to any given path if it is missing.
    .DESCRIPTION
Powershell usually returns path without a backslash.
    This function takes care of that.
    We need not expose this to the environment.
    .EXAMPLE
Add-BackSlashToPath -Path "C:\Test-PS-1"
    C:\Test-PS-1\
    .EXAMPLE
    Add-BackSlashToPath -Path C:\Windows\System32\
    C:\Windows\System32\
    .EXAMPLE
    Add-BackSlashToPath -Path \\comp1\C$\Windows\System32
    \\comp1\C$\Windows\System32\
#>
    
    try
    {
        $dirSepChar = [IO.Path]::DirectorySeparatorChar
        if(Test-Path -Path $Path -IsValid){
            if($Path -match "\\$"){
                $strPath = $Path
            }else{
                $strPath = $Path + "$dirSepChar"
            }
        } else{
            $strPath = ".${dirSepChar}"
    }
    $strPath
    }
    catch
    {
        $ex = $_.Exception
        $excMsg = $ex.Message.ToString()
        Write-Host "[Add-BackSlashToPath]: $($excMsg)" -Fore Red
        while ($ex.InnerException)
        {
            $ex = $ex.InnerException
            $excMsg = $ex.InnerException.Message.ToString()
            Write-Host "[Add-BackSlashToPath]: $($excMsg)" -Fore Red
        }
    }
    
}