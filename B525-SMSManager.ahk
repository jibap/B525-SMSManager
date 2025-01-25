#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance force ; Force erase previous instance



DllCall("AllocConsole")
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

OnMessage(0x404, Func("clicOnNotif")) ; CLIC sur la notif pour ouvrir la GUI

; IMPORT / EXPORT des fichiers annexes pour version compilée
FileCreateDir,  medias
FileInstall, medias\noSMS.ico, %A_WorkingDir%\medias\noSMS.ico
FileInstall, medias\more.ico, %A_WorkingDir%\medias\more.ico
FileInstall, medias\load.ico, %A_WorkingDir%\medias\load.ico
FileInstall, medias\net.ico, %A_WorkingDir%\medias\net.ico
FileInstall, manage_sms.ps1, %A_WorkingDir%\manage_sms.ps1
FileInstall, config_sample.ini, %A_WorkingDir%\config.ini


  ; ###   #   #   ###   #####
  ;  #    #   #    #      #
  ;  #    ##  #    #      #
  ;  #    # # #    #      #
  ;  #    #  ##    #      #
  ;  #    #   #    #      #
  ; ###   #   #   ###     #

wifiStatus = 0
lastIcon = noSMS
data := {}
helpText = Double-clic sur une ligne pour afficher et pouvoir sélectionner les détails du SMS dans cette zone

; ICONS
validIconID = 301
outboxIconID = 195
unreadIconID = 209
enableWifiIconID = 53
openWebPageIconID = 136
sendSMSIconID = 215
refreshIconID = 239
deleteIconID = 132
numeroIconID = Icon161
dateIconID = Icon250
messageIconID = Icon157
reduceIconID = 248
cancelIconID = 296
settingsIconID = 315


; GET WINDOWS VERSION
objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\cimv2")
For objOperatingSystem in objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
   windowsVersion := objOperatingSystem.Caption
; IF WINDOWS 10
if(InStr(windowsVersion, "10")){
	validIconID = 297
	unreadIconID = 321
	dateIconID = Icon266
	cancelIconID = 298
	enableWifiIconID = 51
}

; Initialisation personnalisée, le cas échéant, des variables globales
IniRead, ipRouter, %A_WorkingDir%\config.ini, main, ROUTER_IP
if(!ipRouter || !ValidIP(ipRouter)){
	ipRouter = 192.168.8.1 ; Default IP
}
IniRead, loopDelay, %A_WorkingDir%\config.ini, main, DELAY
if(!loopDelay || !RegExMatch(loopDelay,"^\d+$")){
	loopDelay = 300000 ; Default Loop delay for check
}

; Création d'une liste d'icones système pour la ListView
ImageListID := IL_Create(3)
IL_Add(ImageListID, "shell32.dll", validIconID)
IL_Add(ImageListID, "imageres.dll", outboxIconID)
IL_Add(ImageListID, "shell32.dll", unreadIconID)


updateTrayIcon("noSMS")


; CREATION DU TRAYMENU
; *****************************
Menu, tray, NoStandard
Menu, tray, add, Quitter l'application, ExitAppli
Menu, tray, add
Menu, tray, add, Activer le Wifi, SwitchWifi
Menu, tray, add, Envoyer un SMS, SendSMSGUI
Menu, tray, add
Menu, tray, add, Paramètres, openSettings
Menu, tray, add
Menu, tray, add, Ouvrir la page Web, openWebPage
Menu, tray, add, Ouvrir l'interface, OpenListSMSGUI
Menu, tray, add
Menu, tray, add, Actualiser, refresh
Menu, tray, Default,  Ouvrir l'interface

Menu, tray, Icon, Quitter l'application, shell32.dll, %deleteIconID%
Menu, tray, Icon, Paramètres, shell32.dll, %settingsIconID%
Menu, tray, Icon, Activer le Wifi, ddores.dll, %enableWifiIconID%
Menu, tray, Icon, Ouvrir la page Web, shell32.dll, %openWebPageIconID%
Menu, tray, Icon, Envoyer un SMS, shell32.dll, %sendSMSIconID%
Menu, tray, Icon, Actualiser, shell32.dll, %refreshIconID%

; Création de l'interface de liste SMS
Gui, ListSMSGUI: New, +HwndMyGuiHwnd, B525-Manager
Gui, ListSMSGUI:Add, Button, hWndhButton1 x10 y8 w100 r2 vRefreshButton, %A_Space%Actualiser
SetButtonIcon(hButton1, "shell32.dll", refreshIconID, 20)
Gui, ListSMSGUI:Add, Button, hWndhButton2 x240 y8 w220 r2 vReadAllButton, %A_Space%Marquer tous les messages comme lus
SetButtonIcon(hButton2, "shell32.dll", validIconID, 20)
Gui, ListSMSGUI:Add, Button, hWndhButton3 x470 y8 w200 r2 vDeleteAllButton, %A_Space%Supprimer tous les messages
SetButtonIcon(hButton3, "shell32.dll", deleteIconID, 20)
Gui, ListSMSGUI:Add, Button, hWndhButton6 x675 y8 w35 r2, %A_Space%
SetButtonIcon(hButton6, "shell32.dll", settingsIconID, 20)
Gui, ListSMSGUI:Add, ListView, section xs R10 w700 vLVSMS gListSMSTrigger Grid AltSubmit,  | Numéro | Date - Heure | Message
Gui, ListSMSGUI:Add, Picture, section %numeroIconID% w16 h16, shell32.dll
Gui, ListSMSGUI:Add, Edit, ReadOnly ys w150 h20 vFullNumero, 
Gui, ListSMSGUI:Add, Picture, ys %dateIconID% w16 h16, shell32.dll
Gui, ListSMSGUI:Add, Text, ys w200 h20 vFullDate, 
Gui, ListSMSGUI:Add, Picture, section xs %messageIconID% w16 h16, shell32.dll
Gui, ListSMSGUI:Add, Edit, ReadOnly ys w670 h50 vFullMessage, %helpText%
Gui, ListSMSGUI:Add, Button, section xs hWndhButton5  w150 r2 gopenWebPage, %A_Space%Ouvrir la page Web
SetButtonIcon(hButton5, "shell32.dll", openWebPageIconID, 20)
Gui, ListSMSGUI:Add, Button, ys hWndhButtonWifi x200 w140 r2 vWifiStatusButton gSwitchWifi, %A_Space%Activer le Wifi
SetButtonIcon(hButtonWifi, "ddores.dll", enableWifiIconID, 20)
Gui, ListSMSGUI:Add, Button, ys hWndhButton4 x380 w140 r2 gSendSMSGUI, %A_Space%Envoyer un SMS
SetButtonIcon(hButton4, "shell32.dll", sendSMSIconID, 20)
Gui, ListSMSGUI:Add, Button, ys hWndhButtonClose x560 w150 r2 gListSMSGUIGuiClose, Fermer
SetButtonIcon(hButtonClose, "shell32.dll", reduceIconID, 20)
; TODO ?
; Menu, ListRCMenu, Add, Supprimer, ListSMSGUIButtonViderlalistedesmessages
; Menu, ListRCMenu, Add, Marquer comme lu, ListSMSGUIButtonMarquertouslesmessagescommelus
LV_SetImageList(ImageListID)  ; Assign the above ImageList to the current ListView.



 ; ####   #   #  #   #
 ; #   #  #   #  #   #
 ; #   #  #   #  ##  #
 ; ####   #   #  # # #
 ; # #    #   #  #  ##
 ; #  #   #   #  #   #
 ; #   #   ###   #   #

Loop {
	refresh()
	
	Sleep %loopDelay%

	; check if wifi off is set and needed
	IniRead, autoWifiOff, %A_WorkingDir%\config.ini, main, AUTO_WIFI_OFF
	if (autoWifiOff && RegExMatch(autoWifiOff, "^\d{2}:\d{2}$")) {
    ; Récupérer l'heure actuelle
    FormatTime, currentTime,, HH:mm
    if (currentTime >= autoWifiOff) {
      runBoxCmd("deactivate-wifi")
    }
	}
}

 
 ; #####   ###   #   #   ###   #####   ###    ###   #   #   ###
 ; #      #   #  #   #  #   #    #      #    #   #  #   #  #   #
 ; #      #   #  ##  #  #        #      #    #   #  ##  #  #
 ; ####   #   #  # # #  #        #      #    #   #  # # #   ###
 ; #      #   #  #  ##  #        #      #    #   #  #  ##      #
 ; #      #   #  #   #  #   #    #      #    #   #  #   #  #   #
 ; #       ###   #   #   ###     #     ###    ###   #   #   ###

openSettings(){
	Run %A_WorkingDir%\config.ini
}

ExitAppli(){
	ExitApp
}

openWebPage() {
	Global ipRouter
  Run http://%ipRouter%/html/smsinbox.html
}

updateTrayIcon(iconName){
	Global lastIcon
	if !iconName
		iconName := lastIcon
	iconFile := A_WorkingDir . "\medias\" . iconName . ".ico"
	Menu, Tray, Icon, % iconFile
}

waitForNetwork(){
	; Vérification BOX joignable
	Global ipRouter
	cmd := "powershell.exe -ExecutionPolicy Bypass -Command Test-NetConnection " . ipRouter . " -InformationLevel Quiet "	

	objShell := ComObjCreate("WScript.Shell")
	result := % objShell.Exec(cmd).StdOut.ReadAll()

	if(!InStr(result, "True")){	
		Global lastIcon
		Global data
		noticeText = La box 4G est injoignable, veuillez vérifier la connexion...
		quiet := !guiIsActive()
		if(!quiet){	
			TrayTip, Erreur, % noticeText
		}
		Menu, Tray, Tip, % noticeText
		; actualisation de l'icone 
		updateTrayIcon("net")
		lastIcon = net
		data := {}
		Sleep 20000 ; Nouvelle tentative toutes les 20s
		waitForNetwork()
	}
}

runBoxCmd(command){
	cmd := "powershell.exe -ExecutionPolicy Bypass -File " . A_WorkingDir . "\manage_sms.ps1 " . command

	objShell := ComObjCreate("WScript.Shell")
	result := % objShell.Exec(cmd).StdOut.ReadAll()

; Gestion des erreurs
	if(InStr(result,"ERROR")){
		; Cas spécial où il y a une erreur de joignabilité
		if(InStr(result,"Router unreachable")){
			waitForNetwork()
		}else{
			errorText := "Une erreur est survenue : `n`n" . result
			; Cas spécial où il y a une erreur de mot de passe, quitte l'application immédiatement
			if(InStr(result,"PASSWORD")){
				errorText = Le mot de passe configuré est incorrect !`n`nVeuillez vérifier le fichier "config.ini" `n `nNB : Le compte est peut-être aussi verrouillé suite à de trop nombreuses tentatives incorrectes... 
			}
			errorText := errorText . "`n`nL'éxécution du programme est annulée."
			MsgBox, 48, ERREUR ! , % errorText
			ExitApp
		}
	}
	return result
}

convertXMLtoArray(xmldata , rootNode){
	xmldata := RegExReplace(xmldata, "\r")
	xmlObj := ComObjCreate("MSXML2.DOMDocument.6.0")
	xmlObj.async := false
	xmlObj.loadXML(xmldata)
	nodes := xmlObj.selectNodes(rootNode)
	return nodes
}

guiIsActive(){
	Global MyGuiHwnd
	return WinActive("ahk_id " MyGuiHwnd)
}


refreshWifiStatus(force){
	Global wifiStatus
	if(force = True){
		wifiStatus := runBoxCmd("get-wifi")
	}

	; Adaptation des labels du statut WIFI
	wifiLabelCmd = Activer le WIFI
	if(wifiStatus = 1){
		wifiLabelCmd = Désactiver le WIFI
	}
	GuiControl,ListSMSGUI:,WifiStatusButton, % wifiLabelCmd
	Menu, Tray, Rename, 3& , % wifiLabelCmd
}

refresh(){
	Global data
	Global wifiStatus
	Global lastIcon
	Gui, ListSMSGUI:Default
	GuiControl, Disable , RefreshButton 
	GuiControl, Disable , DeleteAllButton 
	GuiControl, Disable , ReadAllButton 
	clearGUI()
	updateTrayIcon("load")

	quiet := !guiIsActive()

	if(!quiet){
		SplashTextOn, 300 , 40 , BOX 4G, Actualisation, merci de patienter...
	}

	; Récupération de tous les comptes de la boite et du statut du wifi
	SMSCountsXML := runBoxCmd("get-count All")

	RegExMatch(SMSCountsXML,"<wifiStatus>(\d+)</wifiStatus>",wifiStatusNode)
	wifiStatus := wifiStatusNode1
	RegExMatch(SMSCountsXML,"<LocalUnread>(\d+)</LocalUnread>",unreadSMSCountNode)
	unreadSMSCount := unreadSMSCountNode1
	RegExMatch(SMSCountsXML,"<LocalInbox>(\d+)</LocalInbox>",inboxSMSCountNode)
	inboxSMSCount := inboxSMSCountNode1
	RegExMatch(SMSCountsXML,"<LocalOutbox>(\d+)</LocalOutbox>",outboxSMSCountNode)
	outboxSMSCount := outboxSMSCountNode1

	refreshWifiStatus(False)

	data := {"inboxSMSCount" : inboxSMSCount, "outboxSMSCount" : outboxSMSCount, "unreadSMSCount" : unreadSMSCount}

	; INBOX
	if(data["inboxSMSCount"] > 0){
		inboxSMSXML := runBoxCmd("get-sms 1") 
		inboxSMSNodes := convertXMLtoArray(inboxSMSXML, "//response/Messages/Message")
		data["inboxSMSList"] := inboxSMSNodes
	}
	; OUTBOX
	if(data["outboxSMSCount"] > 0){
		outboxSMSXML := runBoxCmd("get-sms 2")
		outboxSMSNodes := convertXMLtoArray(outboxSMSXML, "//response/Messages/Message")
	 	data["outboxSMSList"] := outboxSMSNodes
	}

	if(ObjCount(data) > 1 ){

		; Création de la liste
		if(data["inboxSMSCount"] > 0){
			createSmsList(1,data["inboxSMSList"])
		}
		if(data["outboxSMSCount"] > 0){
			createSmsList(2,data["outboxSMSList"])
		}

		; Auto-size
		LV_ModifyCol()
		; Sort by Date  
		LV_ModifyCol(3, "SortDesc")

		; TOOLTIP UPDATE
		If (data["unreadSMSCount"] > 0)
		{
			; Modification du tooltip - pluriel - en fonction du nombre
			if(data["unreadSMSCount"] = 1){
				tooltipTitle = 1 nouveau message
			}else{
				tooltipTitle := data["unreadSMSCount"] . " nouveaux messages"
			}
			lastIcon = more
		}else {
			; Il n'y a aucun message non lu 
			lastIcon = noSMS
			tooltipTitle = Aucun nouveau message
		}
		; actualisation de l'icone 
		updateTrayIcon(lastIcon)
		; actualisation de l'infobulle de l'icone
		Menu, Tray, Tip, % tooltipTitle "`n"data["inboxSMSCount"] " reçu(s) `n"data["outboxSMSCount"] " envoyé(s)"
	}

	if(!quiet){
		SplashTextOff
	}
	GuiControl, Enable , RefreshButton 
	GuiControl, Enable , ReadAllButton 
	GuiControl, Enable , DeleteAllButton 
}


; Permet de valider une IP
ValidIP(IPAddress){
	fp := RegExMatch(IPAddress, "^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$", octet)
	If (fp = 0)
		Return 0
	Loop 4
	{
		If (octet%A_Index% > 255)
			Return 0
	}

	return 1
}

Utf8ToText(ByRef vUtf8){
  if A_IsUnicode
  {
    VarSetCapacity(vTemp, StrPut(vUtf8, "CP0"))
    StrPut(vUtf8, &vTemp, "CP0")
    return StrGet(&vTemp, "UTF-8")
  }
  else
    return StrGet(&vUtf8, "UTF-8")
}

; Fonction spéciale pour les GUI, permet d'afficher une icone dans un bouton
SetButtonIcon(hButton, File, Index, Size := 16) {
    hIcon := LoadPicture(File, "h" . Size . " Icon" . Index, _)
    SendMessage 0xF7, 1, %hIcon%,, ahk_id %hButton%
}

; Fonction qui permets de cliquer sur la notif Windows pour ouvrir la GUI
clicOnNotif(wParam, lParam, msg, hwnd){
	if (hwnd != A_ScriptHwnd)
		return
	if (lParam = 1029)
		openGui()
}

; #      #            #        ##   #  #   ##  			  ##   #  #  ###
; #                   #       #  #  ####  #  # 			 #  #  #  #   #
; #     ##     ###   ###       #    ####   #   			 #     #  #   #
; #      #    ##      #         #   #  #    #  			 # ##  #  #   #
; #      #      ##    #       #  #  #  #  #  # 			 #  #  #  #   #
; ####  ###   ###      ##      ##   #  #   ##  			  ###   ##   ###

openGui(){
	Gui, ListSMSGUI:Show
}

clearGUI(){
	Global helpText
	Gui, ListSMSGUI:Default
	LV_Delete() ; clear the table
	GuiControl,ListSMSGUI:,FullNumero,
	GuiControl,ListSMSGUI:,FullDate,
	GuiControl,ListSMSGUI:,FullMessage, %helpText%
}

createSmsList(boxType, SMSList){
	if( SMSList.Length )	{
		Global MyGuiHwnd
		messages := SMSList.item(0)
		while messages {
			iconID := boxType
			phoneNumber := % messages.getElementsByTagName( "Phone" ).item[0].text
			StringReplace, phoneNumber, phoneNumber, +33, 0 , All
			IniRead, phoneNumber, %A_WorkingDir%\config.ini, contacts, % phoneNumber, % phoneNumber
			phoneNumber := % Utf8ToText(phoneNumber)
			dateMessage := % messages.getElementsByTagName( "Date" ).item[0].text
			dateMessage := "Le " . SubStr(dateMessage, 1, 10) . "  à  " . SubStr(dateMessage, 12, 19)
			contentMessage := % Utf8ToText(messages.getElementsByTagName( "Content" ).item[0].text)
			; Check si le message est "unread", icone spéciale + traytip
			if(messages.getElementsByTagName( "Smstat" ).item[0].text = 0){
					iconID = 3
					; Si le message est trop long (max 120 traytip Windows) alors on coupe et ...
					if (StrLen(contentMessage) > 120){
						contentMessageTT := SubStr(contentMessage, 1, 120) "..."
					}else{
						contentMessageTT := contentMessage
					}
					
					if ! WinExist("ahk_id " MyGuiHwnd){	
						; affichage d'une notification pour chaque message si interface non affichée
						TrayTip, SMS Box4G : %phoneNumber%, %contentMessageTT%	
					}
			}
			StringReplace, contentMessage, contentMessage, `n, %A_Space% ↳ %A_Space%, All
			LV_Add("Icon" . iconID " Select " ,, phoneNumber , dateMessage , contentMessage)				
		  messages := SMSList.nextNode
		}
	}
}

OpenListSMSGUI:
	openGui()
return

; Affichage détaillé d'une ligne si clic dessus
ListSMSTrigger: 
	; préviens les autres clics et force sur le double pour ne pas gêner le clic droit
	If (A_GuiEvent != "DoubleClick"){
	 Return
	}

	; récupère les données de la ligne cliquée
	LV_GetText(longNumero, A_EventInfo, 2) 
	LV_GetText(longDate, A_EventInfo, 3) 
	LV_GetText(longText, A_EventInfo, 4) 

	; met à jour les champs d'affichage complet
	GuiControl,ListSMSGUI:,FullNumero, %longNumero%
	GuiControl,ListSMSGUI:,FullDate, %longDate%
	StringReplace, longText, longText, %A_Space% ↳ %A_Space%, `n, All
	GuiControl,ListSMSGUI:,FullMessage, %longText%

return

; TODO Menu contextuel pour marquer comme lu, supprimer ou répondre
; ListSMSGUIGuiContextMenu:
; 	IF (A_EventInfo) {
; 		rightClickedRow := A_EventInfo 
; 		Menu, ListRCMenu, Show 
; 	}
; return


; TODO with /api/monitoring/status
; <ConnectionStatus>901</ConnectionStatus> = OK
; <SignalIcon>2</SignalIcon>
; <maxsignal>5</maxsignal>

; ContextProperties:  ; The user selected "Properties" in the context menu.
; ; For simplicitly, operate upon only the focused row rather than all selected rows:
; FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
; if not FocusedRowNumber  ; No row is focused.
;     return

ListSMSGUIButton:
	openSettings()
return

ListSMSGUIButtonActualiser:
	refresh()
return

ListSMSGUIButtonMarquertouslesmessagescommelus:
	SplashTextOn, 200 , 50 , BOX 4G : SMS, Marquage en cours...
	runBoxCmd("read-all")
	SplashTextOn, 200 , 50 , BOX 4G : SMS, Marquage terminé !
	Sleep 1000
	SplashTextOff
	refresh()
return

ListSMSGUIButtonSupprimertouslesmessages:
	MsgBox, 49, ATTENTION !, Tous les messages seront supprimés définitivement, c'est sûr ?
	IfMsgBox, OK
	{
		Gui, Hide
	  runBoxCmd("delete-all")
		refresh()
	}
return 


ListSMSGUIGuiEscape:
ListSMSGUIGuiClose:
	Gui, Hide
return 





;  ###                     #   ###   #   #   ###    ###   #   #   ###
; #   #                    #  #   #  #   #  #   #  #   #  #   #    #
; #       ###   # ##    ## #  #      ## ##  #      #      #   #    #
;  ###   #   #  ##  #  #  ##   ###   # # #   ###   #      #   #    #
;     #  #####  #   #  #   #      #  #   #      #  #  ##  #   #    #
; #   #  #      #   #  #  ##  #   #  #   #  #   #  #   #  #   #    #
;  ###    ###   #   #   ## #   ###   #   #   ###    ###    ###    ###

; SOUS-PROGRAME - GUI d'envoi de SMS
; *****************************
SendSMSGUI:
	IniRead, iniList, %A_WorkingDir%\config.ini, contacts
	StringSplit, contactsArray, % Utf8ToText(iniList), `n

	contactsList := ""
	if(StrLen(contactsArray0)){
		Loop, % contactsArray0
		{
	    line := contactsArray%A_Index%
	    egalPos := InStr(line, "=")
	    contactsList .= SubStr(line, egalPos + 1) . " (" . SubStr(line, 1, egalPos - 1) . ")|" 
		}
	}

	Gui, SendSMSGUI: New
	Gui, SendSMSGUI:Add, Text,, Message:
	Gui, SendSMSGUI:Add, Edit, vSMSText w240 r5 ys
	Gui, SendSMSGUI:Add, Text, section xs w65, Destinataire :
	if(StrLen(contactsList)){
		Gui, SendSMSGUI:Add, DropDownList, ys vContactChoice w200 gChangeContact, % contactsList
		Gui, SendSMSGUI:Add, Text, section xs w65, Numéro : 
		GuiControl, SendSMSGUI:Choose, ContactChoice, 1
	}
	Gui, SendSMSGUI:Add, Edit, vNumero ys w80 Limit10 Number
	

	Gui, SendSMSGUI:Add, Button, section xs hWndhButton10 w150 r2 gSendSMSGUIGuiClose, Annuler
	SetButtonIcon(hButton10, "shell32.dll", cancelIconID, 20)
	Gui, SendSMSGUI:Add, Button, ys hWndhButton11 w150 r2, Envoi 
	SetButtonIcon(hButton11, "shell32.dll", validIconID, 20)
	Gui, SendSMSGUI:Show,, Envoi de SMS sur Box4G

ChangeContact:
	if(StrLen(contactsList)){
	  Gui, SendSMSGUI:Submit, NoHide
	  contactChoosen = % SubStr(ContactChoice, InStr(ContactChoice, "(") + 1, -1)
		GuiControl,SendSMSGUI:,Numero, % contactChoosen
	}
return

SendSMSGUIButtonEnvoi:
	Gui, SendSMSGUI:Submit, NoHide
	if(!SMSText){
		MsgBox, 48,Erreur, Aucun message saisi !!
		return
	}

	if(!Numero){
		MsgBox, 48,Erreur, Aucun numéro saisi !!
		return
	}

	IniRead, contactName, %A_WorkingDir%\config.ini, contacts, % Numero
	contactName := % Utf8ToText(contactName)

	if(contactName != "ERROR"){
		dest = à %contactName%
	}else{
		dest = au %Numero%
	}

	MsgBox, 33, Confirmation, Le message suivant va être envoyé %dest% : `n`n "%SMSText%" `n `n Confirmer l'envoi ?
	IfMsgBox, OK
	{
	; suppression des caractères à pb
		StringReplace, SMSText, SMSText, ", """ , All
		StringReplace, SMSText, SMSText, >, _ , All
		StringReplace, SMSText, SMSText, <, _ , All
		Gui, SendSMSGUI:Hide
		SplashTextOn, 200 , 50 , BOX 4G : SMS, Envoi en cours...
		sendReturn := runBoxCmd("send-sms """ . SMSText . """ " . Numero)
		if(InStr(sendReturn, "<response>OK</response>")){
			SplashTextOn, 200 , 50 , BOX 4G : SMS, Le message a bien été envoyé !
			Sleep 1000
			SplashTextOff
			Gui, SendSMSGUI:Destroy
			refresh()
		}else{
			SplashTextOff
			MsgBox, 48, ERREUR, Le message n'a pas pu être envoyé. `n Veuillez vérifier votre saisie...
			Sleep 100
			Gui, SendSMSGUI:Show
		}
	}
	return

SendSMSGUIGuiEscape:
SendSMSGUIGuiClose:
	Gui, SendSMSGUI:Hide
	Return


; #   #  ###    ####   ###            ##    #   #  ###    #####   ##    #  #
; #   #   #     #       #            #  #   #   #   #       #    #  #   #  #
; # # #   #     ###     #             #     # # #   #       #    #      ####
; # # #   #     #       #              #    # # #   #       #    #      #  #
; ## ##   #     #       #            #  #   ## ##   #       #    #  #   #  #
; #   #  ###    #      ###            ##    #   #  ###      #     ##    #  #


SwitchWifi:
	Gui, ListSMSGUI:Default
	updateTrayIcon("load")
	Global wifiStatus
	quietGui := !guiIsActive()
	if(!quietGui){
		GuiControl, Disable ,WifiStatusButton 
	}

	if(wifiStatus = 1){
		SplashTextOn, 200 , 50 , BOX 4G : WIFI, Désactivation du WIFI...
		runBoxCmd("deactivate-wifi")
		wifiStatus = 0
	}	else{
		SplashTextOn, 200 , 50 , BOX 4G : WIFI, Activation du WIFI...
		runBoxCmd("activate-wifi")
		wifiStatus = 1
	}

	SplashTextOff
	refreshWifiStatus(false)
	updateTrayIcon(false) ;Restore previous icon, set by refresh()
	if(!quietGui){
		Sleep 5000 ; evite de changer trop rapidemment quand l'interface est ouverte
		GuiControl, Enable ,WifiStatusButton
	}
	return
