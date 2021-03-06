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
		$Path
	)

    if($Disk = Get-iSCSIVirtualDisk -Path $Path -ErrorAction SilentlyContinue)
    {
        $Ensure = "Present"
    }
    else
    {
        $Ensure = "Absent"
    }

	$returnValue = @{
		Ensure = $Ensure
		Type = $Disk.DiskType
		Path = $Path
		Description = $Disk.Description
		SizeBytes = $Disk.Size
#		BlockSizeBytes = 
#		PhysicalSectorSizeBytes = 
#		LogicalSectorSizeBytes = 
		ParentPath = $Disk.ParentPath
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

		[ValidateSet("Dynamic","Differencing","Fixed")]
		[System.String]
		$Type = "Dynamic",

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Description,

		[System.UInt64]
		$SizeBytes = (100 * 1024 * 1024 * 1024),

		[System.UInt32]
		$BlockSizeBytes,

		[ValidateSet(512,4096)]
		[System.UInt32]
		$PhysicalSectorSizeBytes,

		[ValidateSet(512,4096)]
		[System.UInt32]
		$LogicalSectorSizeBytes,

		[System.String]
		$ParentPath
	)
    
    switch($Ensure)
    {
        "Present"
        {
            $Params = @{
                Path = $Path
                Description = $Description
                SizeBytes = $SizeBytes
            }

            switch($Type)
            {
                "Dynamic"
                {
                    if($PSBoundParameters.ContainsKey("BlockSizeBytes"))
                    {
                        $Params += @{BlockSizeBytes = $BlockSizeBytes}
                    }
                    if($PSBoundParameters.ContainsKey("PhysicalSectorSizeBytes"))
                    {
                        $Params += @{PhysicalSectorSizeBytes = $PhysicalSectorSizeBytes}
                    }
                    if($PSBoundParameters.ContainsKey("LogicalSectorSizeBytes"))
                    {
                        $Params += @{LogicalSectorSizeBytes = $LogicalSectorSizeBytes}
                    }
                    New-iSCSIVirtualDisk @Params
                }
                "Differencing"
                {
                    New-iSCSIVirtualDisk @Params
                }
                "Fixed"
                {
                    if($PSBoundParameters.ContainsKey("ParentPath"))
                    {
                        $Params += @{ParentPath = $ParentPath}
                        New-iSCSIVirtualDisk @Params -UseFixed
                    }
                }
            }
        }
        "Absent"
        {
            Remove-iSCSIVirtualDisk -Path $Path
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

		[ValidateSet("Dynamic","Differencing","Fixed")]
		[System.String]
		$Type = "Dynamic",

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Description,

		[System.UInt64]
		$SizeBytes = (100 * 1024 * 1024 * 1024),

		[System.UInt32]
		$BlockSizeBytes,

		[ValidateSet(512,4096)]
		[System.UInt32]
		$PhysicalSectorSizeBytes,

		[ValidateSet(512,4096)]
		[System.UInt32]
		$LogicalSectorSizeBytes,

		[System.String]
		$ParentPath
	)

	$result = ((Get-TargetResource -Path $Path).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource