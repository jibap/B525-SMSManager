############################
####     FONCTIONS      ####
############################

function IsValidIP($ip) {
    if ($ip -match '^([0-9]{1,3}\.){3}[0-9]{1,3}$') {
        $octets = $ip -split '\.'
        foreach ($octet in $octets) {
            if ([int]$octet -gt 255) {
                return $false
            }
        }
        return $true
    } else {
        return $false
    }
}

function ProcessRouterResponseHeader {
    $NEWTOKEN = $script:SESSION.ResponseHeaders["__RequestVerificationTokenone"]
    if ($NEWTOKEN) { $script:TOKEN = $NEWTOKEN }
    $NEWTOKEN = $script:SESSION.ResponseHeaders["__RequestVerificationToken"]
    if ($NEWTOKEN) { $script:TOKEN = $NEWTOKEN }
    $NEWSESSIONID = $script:SESSION.ResponseHeaders["Set-Cookie"] -split ";" | Where-Object { $_ -like "SessionID=*" }
    if ($NEWSESSIONID) { $script:SESSIONID = $NEWSESSIONID.Substring(0, 138) }
}

function GetSessionToken() {
    $response = GetRouterData '/api/webserver/SesTokInfo'
    if ($response -like "*<SesInfo>*") {
        $xml = [xml]$response
        $script:SESSIONID = "SessionID=" +$xml.response.SesInfo
        $script:TOKEN = $xml.response.TokInfo
    }
}

function AddHeaders{
    $script:SESSION.Headers.Clear()
    $script:SESSION.Headers.Add('Content-Type', 'application/xml; charset=UTF-8')
    $script:SESSION.Headers.Add('__RequestVerificationToken', $script:TOKEN)
    $script:SESSION.Headers.Add('Cookie', "$script:SESSIONID")
}

function GetRouterData($relativeUrl){
    AddHeaders
    $response = $script:SESSION.DownloadString("http://$script:ROUTER_IP$relativeUrl")
    ProcessRouterResponseHeader
    return $response
}

function PostRouterData($relativeUrl, $data, $askNewToken) {
    if ($askNewToken) {
        GetSessionToken
    }
    AddHeaders

    $response = $script:SESSION.UploadString("http://$script:ROUTER_IP$relativeUrl", "<?xml version = `"1.0`" encoding = `"UTF-8`"?>$data")
    ProcessRouterResponseHeader

    [xml]$responseXML = $response

    if ((-not [string]::IsNullOrEmpty($responseXML.error)) -and ($relativeUrl -ne "/api/user/logout") ) {   
        switch ($responseXML.error.code) {
            "125003" { Write-Host "ERROR : TOKEN ERROR" -ForegroundColor Red }
            "100003" { Write-Host "ERROR : UNAUTHORIZED" -ForegroundColor Red }
            "108006" { Write-Host "ERROR : BAD USER OR PASSWORD" -ForegroundColor Red }
            "108007" { Write-Host "ERROR : BAD USER OR PASSWORD" -ForegroundColor Red }
            "108003" { Write-Host "ERROR : TOO MANY USERS CONNECTED" -ForegroundColor Red }
            default {
                Write-Host "UNKNOWN ERROR WITH API REQUEST : " $responseXML.error.code -ForegroundColor Red
                Write-Host $relativeUrl $data
            }
        }
        return
    }
    return $response
}

function b64_sha256($data) {
    $s256 = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
    $dgs256 = $s256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data))
    $hs256 = [System.BitConverter]::ToString($dgs256).Replace("-", "").ToLower()
    return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($hs256))
}

function loggedin_check() {
    $response = GetRouterData '/api/user/state-login'

    if ($response -like "*<password_type>*") {
        $xml = [xml]$response
        $session_state = $xml.response.State

        if ($session_state -eq "0") {
            $loggedin = $true
           #  Write-Host "LOGIN SUCCESS"  -ForegroundColor Green
        }else{
            Write-Host "ERROR : STATE = $session_state"  -ForegroundColor Red
        }
    } 
    if(-not($loggedin)){
        Write-Host "ERROR : LOGIN" -ForegroundColor Red
    }
}

function Login() {
    GetSessionToken

    # HASH PASSWORD
    $password = b64_sha256($script:ROUTER_PASSWORD)
    $authstring = $script:ROUTER_USERNAME + $password + $script:TOKEN
    
    # HASH WITH TOKEN
    $credentials = b64_sha256($authstring)


    $data = "<request><Username>$script:ROUTER_USERNAME</Username><Password>$credentials</Password><password_type>4</password_type></request>"
    $response = PostRouterData "/api/user/login" $data
    if ($response -like "*<response>OK*") {
        loggedin_check($session)
    }
}

function Logout() {
    $response = PostRouterData "/api/user/logout" "<request><Logout>1</Logout></request>"
}

function GetCount($boxType) {
    $wifiStatus = GetWifiStatus
    $response = Invoke-WebRequest -Method GET -Uri "http://$script:ROUTER_IP/api/sms/sms-count"
    [xml]$responseXML = $response.Content
    if ($boxType -ne "All") {
        $counts = $responseXML.response."Local$boxType"
    } else {
        $nodeWifi = $responseXML.CreateElement("wifiStatus")
        $nodeWifi.InnerText = $wifiStatus
        $parentNode = $responseXML.SelectSingleNode("//response")
        $addWifi = $parentNode.AppendChild($nodeWifi)
        $counts = $responseXML.OuterXml
    }
    return $counts
}

function GetSMS($boxType) {
    $response = PostRouterData "/api/sms/sms-list" "<request><PageIndex>1</PageIndex><ReadCount>20</ReadCount><BoxType>$boxType</BoxType><SortType>0</SortType><Ascending>0</Ascending><UnreadPreferred>1</UnreadPreferred></request>" $true
    return $response
}

function TagAllAsRead() {
    $response = GetSMS 1
    [xml]$responseXML = $response
    $messages = $responseXML.response.messages.message

    foreach ($message in $messages) {
        if ($message.Smstat -eq 0) {
            $index = $message.Index
            $response = PostRouterData "/api/sms/set-read" "<request><Index>$index</Index></request>" $true
        }
    }
}

function DeleteSMS($boxType){
    $response = GetSMS $boxType
    [xml]$responseXML = $response
    $messages = $responseXML.response.messages.message
    foreach ($message in $messages) {
        $index = $message.Index
        $response = PostRouterData "/api/sms/delete-sms" "<request><Index>$index</Index></request>" $true
    }
}

function DeleteAll($boxType) {
    DeleteSMS 1 #reçus
    DeleteSMS 2 #envoyés
}

function SendSMS($number, $message) {
write-host $message
    $message = $message -replace "_NL_", "`n"
    $data = "<request><Index>-1</Index><Phones><Phone>$number</Phone></Phones><Sca></Sca><Content>$message</Content><Length>$($message.Length)</Length><Reserved>1</Reserved><Date>$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</Date></request>"
    $response = PostRouterData "/api/sms/send-sms" $data $true
    return $response
}

function GetWifiStatus() {
    $response = GetRouterData '/api/monitoring/status'
    [xml]$responseXML = $response
    $status = $responseXML.response.WifiStatus
    return $status
}

function ChangeWifiStatus($status) {
    $data = "<request><radios><radio><wifienable>$status</wifienable><index>0</index><ID>InternetGatewayDevice.X_Config.Wifi.Radio.1.</ID></radio><radio><wifienable>$status</wifienable><index>1</index><ID>InternetGatewayDevice.X_Config.Wifi.Radio.2.</ID></radio></radios><WifiRestart>1</WifiRestart></request>"
    $response = PostRouterData "/api/wlan/status-switch-settings" $data $true
}

############################
#### BEDUT DU PROGRAMME ####
############################

# Force le dossier d'éxécution
Set-Location -Path $PSScriptRoot

$CONFIG_FILE = "config.ini"
# $TMP_HEADER_FILE = "$env:TEMP\headers.tmp"

if (-not (Test-Path $CONFIG_FILE)) {
    Write-Host "ERROR: Config file [config.ini] not found" -ForegroundColor Red
    #Exit
}

$CONFIG = Get-Content $CONFIG_FILE | Where-Object {$_ -match "="} | ConvertFrom-StringData
$script:ROUTER_IP = if (($CONFIG.ROUTER_IP) -and (IsValidIP($CONFIG.ROUTER_IP))) { $CONFIG.ROUTER_IP } else { '192.168.8.1'}
$script:ROUTER_USERNAME = if ($CONFIG.ROUTER_USERNAME) { $CONFIG.ROUTER_USERNAME } else { 'admin' }
$script:ROUTER_PASSWORD = if ($CONFIG.ROUTER_PASSWORD) { $CONFIG.ROUTER_PASSWORD } else { Write-Host "ERROR: No password configured" -ForegroundColor Red; exit }
$script:SESSIONID = ""
$script:TOKEN = ""

if(-not(Test-NetConnection $script:ROUTER_IP -InformationLevel Quiet)){
    Write-Host "ERROR : Router unreachable > $script:ROUTER_IP"
    exit
}

# GESTION DES ARGUMENTS

$syntax = "
Usage: manage_sms.ps1 <command> 

Commands:
    get-count [Unread,Inbox,Outbox,All]
    get-sms [1=reçus (par defaut), 2=envoyés]
    read-all
    delete-sms [1=reçus (par defaut), 2=envoyés]
    delete-all
    get-wifi
    activate-wifi
    deactivate-wifi
    send-sms <Message> <Numero>"

if ($args.Count -lt 1) {
    Write-Host "ERROR: At least 1 parameter required" -ForegroundColor Red
    Write-Host $syntax
    exit
}

if ($args[0] -eq "get-count") {
    $getCountOptions = @("Unread", "Inbox", "Outbox", "All")
     
    if (-not $args[1] -or !($getCountOptions -contains $args[1])) {
        Write-Host "ERROR: Second parameter required, available options: <Unread / Inbox / Outbox / All>" -ForegroundColor Red
        exit
    } else {
        $BOX_TYPE = $args[1]
    }
}

if ($args[0] -eq "get-sms") {
    if (-not $args[1] -or ($args[1] -ne "1" -and $args[1] -ne "2")) {
        $BOX_TYPE = 1
    } else {
        $BOX_TYPE = $args[1]
    }
}

if ($args[0] -eq "delete-sms") {
    if (-not $args[1] -or ($args[1] -ne "1" -and $args[1] -ne "2")) {
        $BOX_TYPE = 1
    } else {
        $BOX_TYPE = $args[1]
    }
}

if ($args[0] -eq "send-sms") {
    if (-not $args[1]) {
        Write-Host "ERROR: Second parameter required <Message>" -ForegroundColor Red
        exit
    } else {
        $SMS_TEXT = $args[1]
    }

    if (-not $args[2]) {
        Write-Host "ERROR: Third parameter required <Numero>" -ForegroundColor Red
        exit
    } else {
        $SMS_NUMBER = $args[2]
    }
}

if (($args[0] -ne "get-count")){
    $script:SESSION = New-Object System.Net.WebClient
    $script:SESSION.Encoding = [System.Text.Encoding]::UTF8 # Nécessaire pour l'envoi de caractères spéciaux dans les SMS
    Login
}

switch ($args[0]) {
    "get-count" { GetCount $BOX_TYPE }
    "get-sms" { GetSMS $BOX_TYPE }
    "read-all" { TagAllAsRead }
    "delete-sms" { DeleteSms $BOX_TYPE }
    "delete-all" { DeleteAll }
    "send-sms" { SendSMS $SMS_NUMBER $SMS_TEXT }
    "get-wifi" { $status = GetWifiStatus; Write-Host -NoNewline $status }
    "activate-wifi" {  ChangeWifiStatus "1" }
    "deactivate-wifi" { ChangeWifiStatus "0" }
    default {
        Write-Host "ERROR: Command '$($args[0])' unavailable" -ForegroundColor Red
        Write-Host $syntax
    }
}

if (($args[0] -ne "get-count") -and ($args[0] -ne "get-wifi")){
    Logout
}
