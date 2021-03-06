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
		[parameter(Mandatory = $true)]
		[System.String]
		$ComputerName,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [ValidateRange(1,[Uint64]::MaxValue)]
        [Uint64]
        $RetryIntervalSec = 1, 

        [Uint32]
        $RetryCount = 0
	)

	$returnValue = @{
		ComputerName = $ComputerName
		TargetName = $TargetName
		Path = $Path
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ComputerName,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [ValidateRange(1,[Uint64]::MaxValue)]
        [Uint64]
        $RetryIntervalSec = 1, 

        [Uint32]
        $RetryCount = 0
	)

    $Found = $false
    Write-Verbose -Message "Testing for iSCSI Virtual Disk $Path mapping $TargetName on $ComputerName..."

    for($count = 0; $count -lt $RetryCount; $count++)
    {
        if(Invoke-Command -ComputerName $ComputerName -Credential $SetupCredential {
            $TargetName = $args[0]
            $Path = $args[1]
            (Get-iSCSIServerTarget -TargetName $TargetName -ErrorAction SilentlyContinue).LunMappings | Where-Object {$_.Path -eq $Path}
        } -ArgumentList @($TargetName,$Path)
        )
        {
            $Found = $true
        }

        if($Found)
        {
            break
        }
        else
        {
            Write-Verbose -Message "iSCSI Virtual Disk $Path mapping $TargetName on $ComputerName not ready. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
        }
    }

    if(!($Found))
    {
        throw New-TerminatingError -ErrorType iSCSIDiskNotReady -FormatArgs @($Path,$TargetName,$ComputerName,$count,$RetryIntervalSec)
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ComputerName,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SetupCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$TargetName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

        [ValidateRange(1,[Uint64]::MaxValue)]
        [Uint64]
        $RetryIntervalSec = 1, 

        [Uint32]
        $RetryCount = 0
	)

        if(Invoke-Command -ComputerName $ComputerName -Credential $SetupCredential {
            $TargetName = $args[0]
            $Path = $args[1]
            (Get-iSCSIServerTarget -TargetName $TargetName -ErrorAction SilentlyContinue).LunMappings | Where-Object {$_.Path -eq $Path}
        } -ArgumentList @($TargetName,$Path)
        )
        {
            $result = $true
        }
        else
        {
            $result = $false
        }

	$result
}


Export-ModuleMember -Function *-TargetResource