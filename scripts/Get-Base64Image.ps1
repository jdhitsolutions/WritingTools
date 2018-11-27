Function Get-Base64Image {
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory,HelpMessage="Enter the path to the image file")]
        [ValidateScript({Test-Path $_)}]
        [string]$Path
    ) 
    [Convert]::ToBase64String((Get-Content $Path -Encoding Byte))
}

<#
#Usage 

if ($ImagePath) {
        if (Test-Path -Path $ImagePath) {

        $HeaderImage = Get-Base64Image -Path $ImagePath

        $ImageHTML = @"
            <img src="data:image/jpg;base64,$($HeaderImage)" style="left:
 150px" alt="System Inventory">
"@
        }
    else {
        throw "$($ImagePath) is not a valid path to the image file"
        }
}
#>
