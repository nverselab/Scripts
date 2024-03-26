			# Remove any AppxPackage named MicrosoftTeams
			Get-AppxPackage -Name "MicrosoftTeams" -AllUsers | Remove-AppxPackage
			
			# Remove any AppXProvisionedPackage named MicrosoftTeams
			Get-AppXProvisionedPackage -Online | Where {$_.DisplayName -eq "MicrosoftTeams"} | Remove-AppxProvisionedPackage -Online
			
			# Remove any AppxPackage named OutlookForWindows
			Get-AppxPackage -Name *OutlookForWindows* | Remove-AppxPackage -ErrorAction stop
