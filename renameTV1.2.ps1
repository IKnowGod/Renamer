## TV show/Anime name replacement script
#
#	Purpose: This script will take any file names of media specified and rename the 
#			files according to the season and episode number.
#
#	Version 1.2
#
#	New In: 1.1: 	- fixed the iteration so it only goes through each media file once
#			1.2:	- accounts for season folders names that arent just named "season xx"
#					- removes additional special charters
#					- accounts for additional sets of numbers in the season name, under 30 seasons
#					- adds a leading zero on filename if season is under 10
#
#	Assumptions: if the media is divided by season then the season folder name REQUIRES to have 
#				the text SEASON in the folder name.
#
#	Usage: .\scriptname.ps1 "path to episodes"
#
#	Notes: need to add multi episode 
#
##

#input the path of the folder you want to convert
param([string]$inputPath)

#get the current path to return to later
$returnPath = Get-Item . | Select FullName
$returnPath = $returnPath.FullName

cd "$inputPath"
$fileArray = @()
$currentPath = Get-Item .. | Select name
$currentSeason = Get-Item . | Select name

$extentionArray = @(".avi",".mkv",".mp4",".srt",".MP4",".mpg",".mov",".rm",".asf",".rmvb",".ogm",".ts")
$fileNumber = 1


# get the current folder in case its the show name and not a season
[string]$seasonName = $currentSeason.name

$currentSeason -match '(\d+)\D+(\d+)'
$matches
echo ("matches.count----" + $matches.count)
if ($matches.count -gt '0') { #if there is more then one match
	$seasonNum = $matches[$matches.count-1]
	echo ("season number -->" + $seasonNum)
	echo "get here 1"
	if ([int]$seasonNum -lt '10') {
		echo "get here 2"
		$currentSeasonNum = "0" + $matches[$matches.count-1]
	}else {
		echo "get here 3"
		$seasonNum = $matches[$matches.count-1]
		$currentSeasonNum = $matches[$matches.count-1]
	}
}else { #if there is only one match
echo "get here 4"
	$currentSeason -match '\d+'
	$seasonNum = $matches[0]
	
	if ($seasonNum -lt '10') {
	echo "get here 5"
		$currentSeasonNum = "0" + $matches[0]
	}else {
	echo "get here 6"
		$currentSeasonNum = $matches[0]
	}
	
}


echo ("current season number -->" + $currentSeasonNum)

# Get the season we are dealing with, records it to VAR
# remove all these special characters
[string]$currentSeason = $currentSeason.name -replace " ", ""
[string]$currentSeason = $currentSeason -replace "-", ""
[string]$currentSeason = $currentSeason -replace " - ", ""
[string]$currentSeason = $currentSeason -replace "_", ""
[string]$currentSeason = $currentSeason -replace "\(", ""
[string]$currentSeason = $currentSeason -replace "\)", ""
[string]$currentSeason = $currentSeason -replace "\[", ""
[string]$currentSeason = $currentSeason -replace "\]", ""
[string]$currentSeason = $currentSeason -replace "\.", ""

# current season at this point is the current folder name without all the special characters noted above
if ([int]$seasonNum -lt '10'){
	#put a "Q" in the name to help matching in case there is no season folder or if there is text before the season text
	$currentSeason = $currentSeason -replace "Season","qs0" 
}else{
	$currentSeason = $currentSeason -replace "Season","qs"
}
echo $currentSeason
if ((($currentSeason -notlike "*qs0*") -and ($currentSeason -notlike "*qs1*") -and ($currentSeason -notlike "*qs2*")) -or ($currentSeason -like "* qs")){
	$currentSeason = $currentSeason -replace "qs", " - s"
}else {

	$currentSeason = $currentSeason -replace "qs", "s" #remove the Q from the QS match
}

#primary loop that looks for files of a specific type defined in the ExtentionArray
for ($j=0; $j -lt $extentionArray.count-1; $j++) {
	$currentExtension = $extentionArray[$j]
	echo ("Current Extension: " + $currentExtension)
	$fileArray = get-ChildItem | where {$_.name -like "*$currentExtension"} | Select name 
	$fileArray = $fileArray | sort-object {[string]$_.name} # sort by name as one string
	
	foreach ($file in $fileArray){
		[string]$tempName = $file.name
		[string]$orgName = $file.name
		$tempName = $tempName.substring(0,$tempName.length-4) #removes the last 4 digits on the file name
		$tempMatches = select-string '(\d+)' -input $tempName -AllMatches | Foreach {$_.matches} | Foreach {$_.value} #match any number series 1, or 01, or 11 
# issue with this line as it will  match 1 or more digits on the string, what happens if there are more then one set of digits?
		
		#echo ($tempMatches)
		# no matter how many matches are made with digits in the file name it will get the first match
		if ($tempMatches.count -gt 1){
			$fileNumber = $tempMatches[1]
		}else{
			$fileNumber = $tempMatches
		}
		
		echo ($fileNumber + " new file number")
		#echo ($tempName + " - before name change")
		#echo ($currentSeason + "   current season")
		if ([int]$fileNumber -lt '10'){
			if ($fileNumber -like "0*"){ #account for extra 0 in front
				if ($currentSeason -like "* - s*"){ 
					$tempName = $currentSeason +"e" + $fileNumber
				}elseif ($seasonName -like "*season*"){ # if there is a season folder
					if ($seasonName -like "season*") { # if the season folder has text before Season
						$tempName = $currentPath.name + " - " + $currentSeason +"e" + $fileNumber
					}else { # if there is additional text, remove it before setting name
						$tempName = $currentPath.name + " - s" + $currentSeasonNum +"e" + $fileNumber
					}
				}else { # is no season name, dont put season in the name
					$tempName = $seasonName + " - e" + $fileNumber
				}
			}else{ #less then 10 with no leading 0 for the fileNumber
				if ($currentSeason -like "* - s*"){
					$tempName = $currentSeason +"e0" + $fileNumber
				}elseif ($seasonName -like "*season*"){
										if ($seasonName -like "season*") { # if the season folder has text before Season
						$tempName = $currentPath.name + " - " + $currentSeason +"e" + $fileNumber
					}else { # if there is additional text, remove it before setting name
						$tempName = $currentPath.name + " - s" + $currentSeasonNum +"e0" + $fileNumber
					}
				}else {
					$tempName = $seasonName + " - e0" + $fileNumber
				}
			}
		}else{ # if the episode number is 10 or more
			if ($currentSeason -like "* - s*"){
				$tempName = $currentSeason +"e" + $fileNumber
				}elseif ($seasonName -like "*season*"){
					if ($seasonName -like "season*") { # if the season folder has text before Season
						$tempName = $currentPath.name + " - " + $currentSeason +"e" + $fileNumber
					}else { # if there is additional text, remove it before setting name
						$tempName = $currentPath.name + " - s" + $currentSeasonNum +"e" + $fileNumber
					}
				}else {
					$tempName = $seasonName + " - e" + $fileNumber
				}
		}
		echo ($tempName + " - after name change
		")

		#code goes here to actually rename the file
		Rename-Item ".\$orgName" "$tempName$currentExtension" -ErrorAction silentlycontinue
	}
}
cd "$returnPath"