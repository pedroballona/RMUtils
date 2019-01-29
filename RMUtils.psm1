Set-Variable DBPath -option Constant -value "\\tecnologiabh\VersoesHomologacao\BaseDeDadosSQL\"

function Get-DBVersions {
    param(
        [Parameter(Mandatory=$false)][string]$Name
    )
    Get-ChildItem $DBPath -Filter "Versao*" -Directory | ForEach-Object{
        [PSCustomObject]@{
            Version=$_
            Path=Join-Path -Path $DBPath -ChildPath $_
        }
    } | Where-Object {!($Name) -or $_.Version -match $Name}
}