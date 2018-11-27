Function Test-MarkdownLink {
<#
.Synopsis
Test links in markdown files
.Description
This command will parse a markdown file looking for links and verify that the link is valid. 
Potential problems are logged to a text file in your Temp directory. The command uses regular
expression parsing to identify links but the patterns are not foolproof. Depending on what the 
author has done, this command may report false positives.

All other potential link problems are always logged.
.Parameter Path
The path to a markdown file.
.Parameter HTTP
Test any web links that start with http.
.Parameter Image
Test any image links.
.Example
PS C:\> Test-MarkdownLink -Path C:\powershell-conference-book\manuscript\schumacher-sccm.md -http -image
Processing C:\powershell-conference-book\manuscript\schumacher-sccm.md
Validating https://www.microsoft.com/en-us/download/details.aspx?id=42645
Validating https://blogs.technet.microsoft.com/pstips/2014/06/09/dynamic-validateset-in-a-dynamic-parameter/
Validating images/schumacher-dynparam3.png
Validating images/schumacher-dynPBreak.png
Validating images/schumacher-dynparam2.png
Validating images/schumacher-dynparam4.png
Validating images/schumacher-dynparam5.png
Validating https://github.com/crshnbrn66/SccmUtilities/blob/master/scripts/Get-CMLog.ps1
Validating https://github.com/crshnbrn66/SccmUtilities/blob/master/scripts/Get-CCMSpecificLog.ps1
Validating https://github.com/crshnbrn66/SccmUtilities/blob/master/scripts/Get-CCMLog.ps1

No apparent link problems detected.

Test a single file for both web and image links

.Example
PS C:\> dir c:\powershell-conference-book\manuscript\*.md -exclude last* | Test-MarkdownLink -image

Check all markdown files in the manuscript folder for image problems.

.Notes
Last updated July 13, 2018
version 0.9.1

.Link
Invoke-WebRequest
.Link
Test-Path
#>

[cmdletbinding()]
Param(
    [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullorEmpty()]
    [ValidateScript({Test-Path $_})]
    [ValidatePattern("\.md$")]
    [String]$Path,
    #test http and https links"
    [switch]$Http,
    #test image links
    [switch]$Image
)
    
Begin {
    #save current location
    Push-Location

    [regex]$linkpattern = "\[.*\](.)?(.*?).*"
    #"\[.*\]\((.*?)\)"
    [regex]$rx = "(?<=\]\()(?<link>.*?)(?=\))"
    $logname = "{0}-linkcheck.txt" -f (get-date -Format "yyyyMMddhhmm")
    $log = Join-path -Path $env:temp -ChildPath $logname
}
Process {
    #this must be run from the location of the file
    Write-Host "Processing $path" -ForegroundColor magenta

    $parent = Get-Item -path (convert-path $path)
    Set-Location -path $parent.Directory

    $all = get-content $path | Select-string -Pattern $linkpattern |
        Select-object -ExpandProperty Matches | Select-object Value

        foreach ($item in $all) {
        $value = $rx.Match($item.value).value
        Write-Host "Validating $value" -ForegroundColor cyan
        if ($value -match "http" ) {
            if ($http) {
                Try {
                    $wr = Invoke-WebRequest -UseBasicParsing -DisableKeepAlive -Uri $value -ErrorAction Stop
                    if ($wr.statuscode -ne 200) {
                        Write-Warning "Failed to verify $Value. Status code $($wr.statuscode)"
                    }
                }
                Catch {
                    Write-Warning "Failed to verify $Value"
                    "Failed to verify $value in $path" | Out-File -filepath $log -append 
                }
            } #if http test
        }
        elseif ($value -match "images") {
            if ($Image) {
                if (-not (Test-Path -Path $value)) {
                    write-warning $value
                    "Failed to verify $value in $path" | Out-File -filepath $log -append
                }
            } #if test images
        }
        elseif ($value -match "^#|\.md") {
            Write-Warning "Detected internal link: $value"
            "Detected internal link: $value in $path" | Out-File -filepath $log -append
        }
        else {
            $msg = "There is a potential problem with $($item.value) in $path"
            write-warning $msg
            $msg | Out-File $log -append
        }
    }
} #process

End {
    If (Test-Path -Path $log) {
        Write-Host "`nSee $log for any problems although some items may be false positives dues to regular expression limitations." -ForegroundColor yellow
    }
    else {
        Write-Host "`nNo apparent link problems detected." -ForegroundColor green
    }
    #change back to original location
    Pop-Location
} #end

} #close function