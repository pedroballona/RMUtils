Set-Variable DBPath -option Constant -value "\\tecnologiabh\VersoesHomologacao\BaseDeDadosSQL\"

function Get-RMDBVersions {
    param(
        [Parameter(Mandatory=$false)][string]$Version
    )
    Get-ChildItem $DBPath -Filter "Versao*" -Directory | ForEach-Object{
        [pscustomobject]@{
            Version=$_
            Path=Join-Path -Path $DBPath -ChildPath $_
        }
    } | Where-Object {!($Version) -or $_.Version -match $Version}
}

function New-TemporaryDirectory {
    $parent = "C:\"
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Restore-RMDB {
    [cmdletbinding()]
    param (
        [Parameter(ParameterSetName="FromParameter", Mandatory=$true)][string]$Version,
        [Parameter(ParameterSetName="FromInput", Mandatory=$true, ValueFromPipeline=$true)][pscustomobject]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name
    )
    if(!($InputObject)) {
        $InputObject = Get-RMDBVersions -Version $Version | Select-Object -Index 0
    }
    $TempDir = (New-TemporaryDirectory).FullName
    $ZipDir = Join-Path $InputObject.Path "\CorporeRM\Dados"
    $ZipFile = (Get-ChildItem $ZipDir -Filter "EXEMPLO*.zip" | Select-Object -Index 0).FullName
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir
    $BakFile = (Get-ChildItem $TempDir -Filter "*.bak" | Select-Object -Index 0).FullName
    try {
        $RelocateData = Join-Path "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\" ("{0}.mdf" -f $Name)
        $RelocateLog = Join-Path "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\" ("{0}.ldf" -f $Name)
        $Query = "RESTORE DATABASE [{0}] FROM  DISK = N'{1}' WITH  FILE = 1,  MOVE N'Exemplo_Data' TO N'{2}',  MOVE N'Exemplo_Log' TO N'{3}',  NOUNLOAD,  STATS = 5" -f $Name, $BakFile, $RelocateData, $RelocateLog
        sqlcmd -Q $Query
    }
    finally {
        Remove-Item -Recurse -Force -Path $TempDir
    }
    Invoke-Command -ScriptBlock {sqlcmd -i (Join-Path $ZipDir "Usuarios SQL 2012.sql") -d $Name } -ErrorAction SilentlyContinue | Out-Null
}