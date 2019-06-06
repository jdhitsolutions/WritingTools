<#
 Define your spoofed string replacements. They are case-sensitive.
 Because replacements are case sensitive, for items that are
 duplicates in text but have different cases, append _#<number>
 to the key name.

 Using a blank value should drop the key value altogether.
#>
@{
    "COMPANY"       = "CORP"
    "company_#1"    = "corp"
    "Company_#2"    = "Corp"
    "local"         = "com"
    "pri"           = "com"
    "LOCAL_#1"      = "COM"
    "CHI-"          = ""
    "chi-_#1"       = ""
    "Chi-_#2"       = ""
    "WIN10"         = "Win10Ent"
    "win10_#1"      = "win10ent"
    "74.122.238.41" = "10.11.12.13"
    "BOVINE320"     = "SRV01"
    "bovine320_#2"  = "srv01"
    "THINKP1"       = "SRV02"
    "thinkp1_#2"    = "srv02"
}