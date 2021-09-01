#Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Get-NetFirewallProfile │select name, enabled
