<#
Typical flow:

$a = Get-CHeader
Copy-JiraComponents -pHeaders $a -pOrgProject "XXX" -pDestinationProject "ZZZ" -pBaseURI "https://jira.mycompany.com/rest/api/2/" 
#>


function Get-CHeader {
	$creds = Get-Credential
	$user = $creds.UserName
	$pass = $creds.GetNetworkCredential().Password
	$pair = $user + ':' + $pass
	$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
	$basicAuthValue = "Basic $encodedCreds"
	$Headers = @{
		Authorization = $basicAuthValue
	}
	Write-Output $Headers
}


function Copy-JiraComponents
{
	Param ([hashtable]$pHeaders, [string]$pOrgProject, [string]$pDestinationProject, [string]$pBaseURI)

	$org_uri = ($pBaseURI+"project/"+$pOrgProject+"/components") 
	$dest_uri = ($pBaseURI+"component") 
	Write-Host $org_uri
	Write-Host $dest_uri

	# Get list of compnents from the original Jira project
	$org_components = Invoke-RestMethod -Uri $org_uri -Method get -ContentType "application/json" -Headers $pHeaders
    
	foreach ($component in $org_components.GetEnumerator()) 
	{ 
		Write-Host $component
		$new_component = New-Object psobject # memory leak?
		$new_component | Add-Member -MemberType NoteProperty -Name name -Value ($component.name)
		$new_component | Add-Member -MemberType NoteProperty -Name description -Value ($component.description)
		# $new_component | Add-Member -MemberType NoteProperty -Name leadUserName -Value ($component.leadUserName)
		# $new_component | Add-Member -MemberType NoteProperty -Name assigneeType -Value ($component.assigneeType)
		# $new_component | Add-Member -MemberType NoteProperty -Name isAssigneeTypeValid -Value ($component.isAssigneeTypeValid)
		$new_component | Add-Member -MemberType NoteProperty -Name project -Value ($pDestinationProject)
		# $new_component | Add-Member -MemberType NoteProperty -Name projectId -Value (666)

		$new_component_json = ConvertTo-Json $new_component
		Write-Host $new_component_json

		Invoke-RestMethod -Uri $dest_uri -Method post -ContentType "application/json" -Body $new_component_json -Headers $pHeaders
	}
}
