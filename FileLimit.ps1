function FileLimit{
    [CmdletBinding(DefaultParameterSetName='default')]
    param( 
        #Top Folder where search begins
        #Default = Current Location from Get-Location
        [Parameter(ParameterSetName = 'default')]
        [string]$BasePath = (Get-Location),

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
        $folderQueue = New-Object System.Collection.Queue
        $folderQueue.Enqueue($BasePath.ToString())

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
        while($folderQueue){
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

                    $fileSizeCounter += $currentFile.Length

                    if($fileSizeCounter -gt $FileSizeLimit){
                        $limitReached = $true
                        break

                    }
                }

            }

            if($foldersInCurrentFolder){
                $foldersInCurrentFolder | ForEach-Object {
                    $currentFolder = $_.FullName

                    $folderQueue.Enqueue($currentFolder.FullName)

                }               

            }

        }
    
    }


    End{

        if($limitReached){return}

        return "Total File Size = $fileSize and there are $fileCount files"
    
    }
}
