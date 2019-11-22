function FileLimit{
    [CmdletBinding(DefaultParameterSetName='default')]
    param( 
        #Top Folder where search begins
        #Default = Current Location from Get-Location
        [Parameter(ParameterSetName = 'default')]
        [string]$BasePath = (Get-Location).ToString(),

        #Size of files
        #Default = 524288000 bytes = 500 MB = 0.5 GB
        [Parameter(ParameterSetName = 'default')]
        [string]$FileSizeLimit = 524288000,
        
        #Number of files
        #Default = 1000 (files)
        [Parameter(ParameterSetName = 'default')]
        [int]$FileCountLimit = 1000,
        
        #Limit search to specific file types
        #Mutually exclusive with ExcludeFileTypes
        #Example: 'exe, jpg, hl7'
        [Parameter()]        
        [string[]] $IncludeFileTypes = 'ALL',
        
        #Exclude certain file types from search
        #Mutually exclusive with IncludeFileTypes
        #If both $IncludeFilesTypes and $ExcludeFileTypes are set,
        #   then $ExcludeFilesTypes will be ignored
        #Example: 'bat, png, pdf'
        [Parameter()]
        [string] $ExcludeFileTypes = 'NONE'          

    )

    Begin{

        #Initialize new folders-to-visit queue with $BasePath as the first element 
        #Then run Breadth-First-Search on all subfolders 
        #until $FileSizeLimit or $FileCountLimit are reached
        # or return size of all files if limits aren't reached
        $folderQueue = New-Object System.Collections.Queue
        $folderQueue.Enqueue($BasePath)

        #$IncludeFileTypes is favored over $ExcludeFileTypes
        if($IncludeFileTypes -ne 'ALL') {
            $ExcludeFileTypes = 'NONE'
            $IncludeFileTypes | ForEach-Object {
                $_ = ".$_"
            }

        } elseif($ExcludeFileTypes -ne 'NONE') {
            $ExcludeFileTypes | ForEach-Object {
                $_ = ".$_"
            }

        }
    
    }


    Process{
        while(($folderQueue.Count -gt 0) -and !($limitReached)){
            $currentFolder = $null
            $filesInCurrentFolder = $null
            $foldersInCurrentFolder = $null

            $currentFolder = $folderQueue.Dequeue()

            if($ExcludeFileTypes -ne 'NONE'){
                $filesInCurrentFolder = Get-Childitem -LiteralPath $currentFolder -File -Force -ErrorAction SilentlyContinue | Where {$_.Extension -notin $ExcludeFileTypes}
            
            } elseif ($IncludeFileTypes -ne 'ALL') {
                $filesInCurrentFolder = Get-Childitem -LiteralPath $currentFolder -File -Force -ErrorAction SilentlyContinue | Where {$_.Extension -in $IncludeFileTypes}
            
            } else {
                $filesInCurrentFolder = Get-Childitem -LiteralPath $currentFolder -File -Force -ErrorAction SilentlyContinue
            }

            $foldersInCurrentFolder = Get-Childitem -LiteralPath $currentFolder -Directory -Force -ErrorAction SilentlyContinue

            if($filesInCurrentFolder){
                $filesInCurrentFolder | ForEach-Object {
                    
                    $currentFile = $_

                    $fileSizeTemp += $currentFile.Length
                    $fileCountTemp += 1

                    if(($fileSizeTemp -gt $FileSizeLimit) -or ($fileCountTemp -gt $FileCountLimit)){
                        $limitReached = $true
                        return
                    }
                }

            }

            if($foldersInCurrentFolder){
                $foldersInCurrentFolder | ForEach-Object {
                    $currentFolder = $_

                    $folderQueue.Enqueue($currentFolder.FullName)

                }               

            }

        }
    
    }


    End{

        if($limitReached){
            return "Limit reached"
            
        }

        $fileSizeInKB = [math]::Round($fileSizeTemp/1KB, 2)
        $fileSizeInMB = [math]::Round($fileSizeTemp/1MB, 2)
        $fileSizeinGB = [math]::Round($fileSizeTemp/1GB, 2)
        
        if($fileSizeInGB -gt 1){
            $fileSize = "$fileSizeinGB GB" 
        } elseif($fileSizeInMB -gt 1) {
            $fileSize = "$fileSizeinMB MB"
        } elseif($fileSizeInKB -gt 1) {
            $fileSize = "$fileSizeinKB KB"
        } else {
            $fileSize = "$fileSizeTemp bytes"
        }

        return "There are $fileCountTemp files and $fileSize of data in base path and all sub directories"
    
    }
}
