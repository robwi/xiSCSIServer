$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xiSCSIServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

    $Mappings = (Get-iSCSIServerTarget -TargetName $TargetName -ComputerName $ComputerName).LunMappings
    if($Mappings | Where-Object {$_.Path -eq $Path})
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }

	$returnValue = @{
		Ensure = $Ensure
		TargetName = $TargetName
		Path = $Path
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

    switch($Ensure)
    {
        "Present"
        {
            Add-iSCSIVirtualDiskTargetMapping -TargetName $TargetName -Path $Path -ComputerName $ComputerName
        }
        "Absent"
        {
            Remove-iSCSIVirtualDiskTargetMapping -TargetName $TargetName -Path $Path -ComputerName $ComputerName
        }
    }

    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource 