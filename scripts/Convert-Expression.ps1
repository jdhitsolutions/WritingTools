

Function Convert-Expression {
<#
.Synopsis
A function to spoof command line output
.Description
This function is designed to allow you to run a PowerShell command but spoof the output. For example, you may have a test domain of Private.pri but you need the output to reflect Company.com. This command will spoof the results to reflect that change.

The command will also spoof the command line entry so that you can capture the screen as well. You are advised to not use any of the Format cmdlets in the expression you wish to spoof.
.Parameter Expression
A PowerShell expression formatted as a string. Avoid using the format cmdlets.
.Example
PS C:\> "Resolve-DnsName company.com" | convert-expression

PS C:\> Resolve-DnsName corp.com

Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
corp.com                                       A      2526  Answer     10.11.12.13

The screen will be cleared after running the intial command. Replacements are made using the default spoof.psd1 file
#>
    [cmdletbinding(SupportsShouldProcess)]
    [Alias("spoof")]
    Param(
        [Parameter(Position = 0, Mandatory,
            HelpMessage = "Enter a PowerShell expression",
            ValueFromPipeline, ValueFromPipelineByPropertyName
        )]
        [Alias("commandline")]
        [ValidateNotNullorEmpty()]
        [string]$Expression,
        [Parameter(HelpMessage = "Enter the path to a psd1 file with case sensitive replacements")]
        [ValidateNotNullorEmpty()]
        [hashtable]$ConfigurationData = $(import-powershelldatafile "$psscriptroot\spoofs.psd1")
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.Mycommand)" 
        #define temp files 
        $out = Join-Path -Path $env:temp -ChildPath 'out.xml'
        $in = Join-Path -Path $env:temp -ChildPath 'in.xml'
        Write-Verbose "Out = $out"
        Write-Verbose "In = $in"
        Write-Verbose "Getting replacement strings from $ConfigurationData"
        $replacements = $ConfigurationData
    } #begin

    Process {
        #run the expression and export 
        Write-Verbose $expression

        if ($PSCmdlet.ShouldProcess($Expression)) {

            Invoke-Expression $Expression | Export-Clixml -Path $out -Force

            #read in the raw xml file
            Write-Verbose "Spoofing output"
            $content = Get-Content $out -Raw

            $replacements.GetEnumerator() | foreach-object {
                #make case sensitive changes
                $m = $_.key -replace "_#\d", ""
                $content = $content -creplace "\b$m\b", $_.Value  
                $Expression = $Expression -creplace "\b$m\b", $_.Value
            }

            #save changes to a new file
            $content | Out-File $in

            if ($VerbosePreference -ne "Continue") {
                #don't clear the screen unless verbose is turned on
                Clear-Host
            }

            #spoof the prompt
            Write-Host (prompt)
            Write-Host "$(prompt)$Expression"

            #spoof the results
            Import-Clixml $in
        }
        else {
            Invoke-Expression -Command $Expression
        }
    } #Process

    End {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    } #end

} #end function


