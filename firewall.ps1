#Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall set allprofiles state off
