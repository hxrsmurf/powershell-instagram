<#
	This manual/basic PowerShell script queries your Instagram account and downloads all photos via pagination.
#>

# Uncomment each line and update with your information
#$clientID = <Your Client ID>
#$secretID = <Your Secret ID>
#$redirectURL = <Your Redirect URL>

$intialAuthURL = "https://api.instagram.com/oauth/authorize"
$clientAuthURL = "?client_id=" + $clientID
$initialRedirectAuthURL = "&redirect_uri=" + $redirectURL
$scopeAuthURL = "&scope=user_profile,user_media"
$responseAuthURL = "&response_type=code"

# Put this in your browser and get the code.
$fullAuthURL = $intialAuthURL + $clientAuthURL + $initialRedirectAuthURL + $scopeAuthURL + $responseAuthURL
Write-Host $fullAuthURL

# Get the code and put here.
$code = ""

# This is the data we need to submit to get a token.
$data = @{
	client_id = $clientID
	client_secret = $secretID
	grant_type = "authorization_code"
	redirect_uri = $redirectURL
	code=$code
}

$getAccessTokenURL = "https://api.instagram.com/oauth/access_token"
$accessToken = ((Invoke-WebRequest -Uri $getAccessTokenURL -Method POST -body $data).content | ConvertFrom-JSON).access_token

# This function paginates through the user's Instagram posts and returns mediaIDs which can be used to get more information about the picture.

function getMediaIDs {
	$mediaIDs = $null
	$initial = $true

	While ($true) {
		if ($initial -eq $true){
			$accessTokenURL = "&access_token=" + $accessToken
			$baseURL = "https://graph.instagram.com/me?fields=id,username" + $accessTokenURL
			$userID = (((Invoke-WebRequest -Uri $baseURL).content) | ConvertFrom-JSON).id
			$mediaURL = "https://graph.instagram.com/" + $userID + "/media?" + $accessTokenURL
			$mediaURLInfo = (Invoke-WebRequest -Uri $mediaURL).content | ConvertFrom-JSON
			$mediaIDs += $mediaURLInfo.data.id
			$initial = $false
		} else {
			$mediaURLPaging = $mediaURLInfo.paging.next
			if ($mediaURLPaging){
			$mediaURLInfo = (Invoke-WebRequest -Uri $mediaURLPaging).content | ConvertFrom-JSON
			$mediaIDs += $mediaURLInfo.data.id
			} else {
				Write-Host "Done!"			
				break
			}
		}
	}	
	return $mediaIDs
}

# This function calls the getMediaIDs function which returns an array of media IDs. Then, we download the images.

function downloadMedia{
	$mediaIDs = getMediaIDs
	$fields = "?fields=id,media_type,media_url,username,timestamp,permalink"	
	$mediaIDURL = "https://graph.instagram.com/" + $mediaID + $fields + $accessTokenURL	
	foreach ($mediaID in $mediaIDs){
		$mediaInfo = (Invoke-WebRequest -Uri $mediaIDURL).content | ConvertFrom-JSON
		Invoke-WebRequest -URI $mediaInfo.media_url -outfile "$mediaID.jpg"
		Write-Host $mediaID
	}
}
