function Get-GrokResponse {
    param (
        [string]$request
    )

    # I was going to integrate some Gen AI, but we're in the automation catagory so this would not add points for us

    # Define the API endpoint
    $uri = "https://api.x.ai/v1/chat/completions"

    # Define the headers
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }

    # Define the body
    $body = @{
        "messages" = @(
            @{
                "role"    = "system"
                "content" = "You are Grok, a chatbot inspired by the Hitchhikers Guide to the Galaxy."
            },
            @{
                "role"    = "user"
                "content" = "$request"
            }
        )
        "model"       = "grok-beta"
        "stream"      = $false
        "temperature"  = 0.9
    } | ConvertTo-Json

    # Make the API request
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

    # Output the response
    return $response.choices.message.content
}

function Get-OpenAIResponse {
    param (
        [string]$request
    )
    # I was going to integrate some Gen AI, but we're in the automation catagory so this would not add points for us

    $api_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

    # Define the API endpoint
    $uri = "https://api.openai.com/v1/chat/completions"

    # Define the headers
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $api_key"
    }

    # Define the body
    $body = @{
        "model"        = "gpt-4o-mini"
        "messages"    = @(
        @{
            "role"    = "system"
            "content" = "You are GPT-4o-mini, an intelligent assistant."
        },
        @{
            "role"    = "user"
            "content" = "$request"
        })
        "temperature"  = 0.9
    } | ConvertTo-Json

    # Make the API request
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body

    # Output the response
    return $response.choices.message.content
}
function Invoke-vCenterLogin{
    $username = "administrator@vsphere.local"
    $securePassword = ConvertTo-SecureString "xxxxxxxxxxxxxxxxxxxxxxxx" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

    Connect-VIServer "vcsa.xxxxxxxxxxxxxxxxxx" -Credential $credential -WarningAction SilentlyContinue
}

function Invoke-vCenterLogout{
    Disconnect-VIServer -Confirm:$false
}

function New-Game{

    $teams = @("A", "B")
    foreach ($team in $teams) {

        for ($i = 1; $i -le 3; $i++) {

            $GameHost = Get-VMHost -Name "esx.lab.local"
            $GameDatastore = Get-Datastore -Name "Local Datastore"
            $GameNetwork = "VM Network"
            $GameFolder = Get-Folder -Name "Hackathon"

            $Player = "Team $team - Player $i"
            Import-VApp -Source "D:\VM.ova" -Name $Player -Datastore  $GameDatastore -VMHost $GameHost
            Get-VM -Name $Player | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $GameNetwork -Confirm:$false
            Move-VM -VM $Player -Destination $GameFolder
            Get-VM -Name $Player | Start-VM
            
        }
    }
}

function Remove-Game{

    $teams = @("A", "B")
    foreach ($team in $teams) {

        for ($i = 1; $i -le 3; $i++) {

            $Player = "Team $team - Player $i"
            Get-VM -Name $Player | Stop-VM -Kill -Confirm:$false
            Get-VM -Name $Player | Remove-VM -DeletePermanently -Confirm:$false
            
        }
    }
    
}

function Get-BattlePair{

    $Players = Get-VM -Location "Hackathon"
    $TeamA = $Players | Where-Object Name -like "Team A*"
    $TeamB = $Players | Where-Object Name -like "Team B*"

    $BattlePair = @($TeamA[0], $TeamB[0])
    
    Write-Host "$($TeamA[0]) will now attack $($TeamB[0])"

    Return $BattlePair

}

function Get-Attack{

    #Select a random attack to use from the list

    $Attacks = @("Suspend", "Change Network","Power Off", "Hard Stop", "Spike CPU")

    #We need to store the associsated commands to run for each attack somewhere and then run it after the battle pair is chosen

}

function Get-IsPlayerOnline{
    param (
        [string]$PlayerVM
    )
    #Use ping to check if the VM is online. Just checking if the VM exists is no good because none of the attacks will delete the VM
    $Player = Get-VM -Name $Player -ErrorAction SilentlyContinue
    
    if ($Player ){
        if ($Player.guest.IPAddress[0]){
            $Global:ProgressPreference = 'SilentlyContinue'
            $Test = Test-NetConnection -ComputerName $Player.guest.IPAddress[0]
            $Global:ProgressPreference = 'Continue'
        }else{
            return $false
        }
    }else{
        return $false
    }

    return $test.pingsucceeded
    
}

function New-Round{

}

function Remove-Player{
    param (
        [string]$Player
    )
   #Remove player from the vSphere inventory if the vSphere admin did not fix it in time
    if ($Player.PowerState -eq "PoweredOn") {
        Stop-VM -Confirm:$true -VM $Player
    }

    $Player | Remove-VM -DeletePermanently -Confirm:$false -RunAsync
}

function Start-Timer{
    param (
        [string]$Player
    )

    Write-Output "$Player has been attaked!"

    Write-Output "You have 30 seconds to resurrect the player before they die"
    
    for ($i = 1; $i -le 6; $i++) {
        
        Start-Sleep -Seconds 5
        
        $PlayerAlive = Get-IsPlayerOnline -PlayerVM $Player

        if ($PlayerAlive){
            Write-Output "Congratulations, you saved the player!"
            #Return true and exit the loop if the player survived, else keep the timer going
            return $true
        }

    }
    #The player must be dead, kill it and return false
    Write-Output "Uh oh! You failed to save the player, they died!"

    Remove-Player -Player $Player

    return $false

}

function Start-Game{
    Write-host "********** Team A vs Team B **********"
}

function Get-GameScore{
$TeamAScore = 0;
$TeamBScore = 0;

    $teams = @("A", "B")
    foreach ($team in $teams) {

        for ($i = 1; $i -le 3; $i++) {
            $GameVMName = "Team $team - Player $i"
            
            if (Get-IsGameVMOnline $GameVMName){
                if ($team -eq "A"){
                    $TeamAScore++
                }
                elseif ($team -eq "B"){
                    $TeamBScore++
                }

            }

        }

    }
return "Team A: $TeamAScore Team B: $TeamBScore"
}

Invoke-vCenterLogin | Out-Null

#New-Game
#Get-IsGameVMOnline -GameVMName "VM2"
#Get-GameScore
#Get-BattlePair
#Remove-Game
#Get-OpenAIResponse -request ""
#Get-GrokResponse -request ""

Invoke-vCenterLogout | Out-Null