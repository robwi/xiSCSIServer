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

		[System.String[]]
		$InitiatorIds,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

	if ($Target = Get-iSCSIServerTarget -TargetName $TargetName -ComputerName $ComputerName -ErrorAction SilentlyContinue)
    {
        $Ensure = "Present"
        $InitiatorIds = @()
        foreach ($InitiatorId in $Target.InitiatorIds)
        {
            $InitiatorIds += "$($InitiatorId.Method):$($InitiatorId.Value)"
        }
    }
    else
    {
        $Ensure = "Absent"
    }

	$returnValue = @{
		Ensure = $Ensure
		TargetName = $TargetName
		InitiatorIds = $InitiatorIds
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

		[System.String[]]
		$InitiatorIds,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

    switch($Ensure)
    {
        "Present"
        {
            New-iSCSIServerTarget -TargetName $TargetName -InitiatorIDs $InitiatorIds -ComputerName $ComputerName
        }
        "Absent"
        {
            Remove-iSCSIServerTarget -TargetName $TargetName -ComputerName $ComputerName
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

		[System.String[]]
		$InitiatorIds,

        [System.String]
        $ComputerName = $env:COMPUTERNAME
	)

	$result = ((Get-TargetResource @PSBoundParameters).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource