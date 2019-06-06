

Function Convert-Expression {
    <#
.Synopsis
A function to spoof command line output.
.Description
This function is designed to allow you to run a PowerShell command but spoof the output. For example, you may have a test domain of Private.pri but you need the output to reflect Company.com. This command will spoof the results to reflect that change.

The command will also spoof the command line entry so that you can capture the screen as well. You are advised to not use any of the Format cmdlets in the expression you wish to spoof. This command may not work properly with other streams such as Write-Warning or when using -Whatif.

.Parameter Expression
A PowerShell expression formatted as a string. Avoid using the format cmdlets.
.Example
PS C:\> "Resolve-DnsName company.com" | convert-expression
PS C:\> Resolve-DnsName corp.com

Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
corp.com                                       A      2526  Answer     10.11.12.13

The screen will be cleared after running the intial command. Replacements are made using the default spoof.psd1 file.test
.Example
PS C:\> Get-History 27 | Convert-Expression

Get the command from history line 27 and re-run it in a spoofed manner using Convert-Expression.

.Example
PS C:\> $c = "thinkp1"
PS C:\> spoof 'Invoke-Command {get-process | sort ws -descending | select -first 10} -computername $c'

PS C:\> Invoke-Command {get-process | sort ws -descending | select -first 10} -computername $c

Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName                PSComputerName
-------  ------    -----      -----     ------     --  -- -----------                --------------
   3744      57   204748     182048   3,221.88   8844   1 SpecialK                   srv02
   3127     487   145196     173140      54.27  10888   1 Dropbox                    srv02
    615      33   113560     134588       2.27  15356   1 powershell                 srv02
    693      72   149252     123404     199.84   6268   0 MsMpEng                    srv02
   1026      63    54760     117428       2.66  10184   1 SearchUI                   srv02
    957      30    88440     111972       1.19  16356   0 wsmprovhost                srv02
   1803      69    38964      97268     148.34   8672   1 explorer                   srv02
      0      12      612      92820       1.86    152   0 Registry                   srv02
   1006      38    40440      88968       2.95   9792   1 ShellExperienceHost        srv02
   1203      52    60220      79664       9.14   5648   0 pwsh                       srv02

This example demonstrates how you might use a variable. The second command is using the spoof alias of this command. Notice that the string is enclosed with a single quote so that the variable will not be expanded. The last part of
the example displays the converted output.
.Inputs
System.String
.Outputs
System.Object[]
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
        [Parameter(HelpMessage = "Enter the path to a psd1 file with case-sensitive replacements")]
        [ValidateNotNullorEmpty()]
        [ValidateScript( {Test-Path $_})]
        [string]$ConfigurationData = "$psscriptroot\spoofs.psd1"
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.Mycommand)"
        #define temp files
        $out = Join-Path -Path $env:temp -ChildPath 'out.xml'
        $in = Join-Path -Path $env:temp -ChildPath 'in.xml'
        Write-Verbose "Out = $out"
        Write-Verbose "In = $in"
        Write-Verbose "Getting replacement strings from $ConfigurationData"
        [hashtable]$replacements = $(Import-PowerShellDataFile $ConfigurationData )

        Write-Verbose ($replacements | Out-String)

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
                write-Verbose "Replacing \b$m\b with $($_.value)"
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

    } #Process

    End {
        if (Test-Path $in) {
            Write-Verbose "Removing $in"
            Remove-Item $in
        }
        if (Test-Path $out) {
            Write-Verbose "Removing $out"
            Remove-Item $out
        }
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    } #end

} #end function

