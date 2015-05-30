// Default Program FrameWork
/*

    This Control Panel provides a Centralized prim for all buttons, and the elevator itself to call in order to obtain
    such configuration information as: 
        (
            Elevator Key,
            Elevtaor ComChannel
            ElevatorMode (On/Off)
        )

    
    Communication Protocol Help
        
        System Requesting Configuration Data
            Data is received on ComChannel Listener
            Request Format:  GETCONFIG||{SYSTEMTYPE}||{Floor}||{AnyOtherData}||
            
*/

// Created by Tech Guy of IO

// Configuration Directives
/* This Section Contains Configuration Variables that will contain data set by reading the notecard specified by ConfigFile Variable */
        
    // Communication Channels
    integer MenuComChannel; // Menu Communications Channel for All User Dialog Communications
    integer ComChannel; // General Communication Channel for Inter-Device Communication
    integer ElevatorChannel;
    key ElevatorKey = NULL_KEY;
    integer OpMode = FALSE;

// System Variables
/* This Section contains variables that will be used throughout the program. */
    // Admin ACL
        list Admins = []; // List of Administrator Keys Read in from ConfigFile
    // Communication Handles
        integer MenuComHandle; // Menu Communications Handle
        integer ComHandle; // General Communications Handle
    // Config Card Reading Variables
        integer cLine; // Holds Configuration Line Index for Loading Config Loop
        key cQueryID; // Holds Current Configuration File Line during Loading Loop
        key UserKey; // Hold Currently Interacting User UUID
    // Configuration Variables
        list Floors = [];
        float SpeedT; // Travel Speed (Used for variabled of same name in elevator engine)
        
        
        
// System Constants
/* This Section contains constants used throughout the program */
string BootMessage = "Booting..."; // Default/Initial Boot Message
string ConfigFile = ".config"; // Name of Configuration File
string EMPTY = "";

// System Status Message
string SystemStatusMessage = "System Online!";
// Main Menu Messages and Button Arragements
string MainMenuMessage = "Elevator Control Panel\n\t";
list MainMenuButtons = [ "Enable", "Disable", "Reset", "Call To" ];

// Color Vectors
list colorsVectors = [<0.000, 0.455, 0.851>, <0.498, 0.859, 1.000>, <0.224, 0.800, 0.800>, <0.239, 0.600, 0.439>, <0.180, 0.800, 0.251>, <0.004, 1.000, 0.439>, <1.000, 0.522, 0.106>, <1.000, 0.255, 0.212>, <0.522, 0.078, 0.294>, <0.941, 0.071, 0.745>, <0.694, 0.051, 0.788>, <1.000, 1.000, 1.000>];

// List of Names for Colors
list colors = ["BLUE", "AQUA", "TEAL", "OLIVE", "GREEN", "LIME", "ORANGE", "RED", "MAROON", "FUCHSIA", "PURPLE", "WHITE"];  

// System Switches
/* This Section contains variables representing switches (integer(binary) yes/no) or modes (string "modename" */
    // Debug Mode Swtich
        integer DebugMode = FALSE; // Is Debug Mode Enabled before Reading Obtaining Configuation Information
        string OpMenu = "";
        

// Imported Functions
/* This section contains any functions that were not written by Tech Guy */

// Home-Brew Functions
/* This section contains any functions that were written by Tech Guy */

// Debug Message Function
DebugMessage(string msg){
    if(DebugMode){
        llOwnerSay(msg);
    }
}

// Send Any User a Message
SendMessage(string msg, key userid){
    if(userid=="NULL_KEY" || userid==""){
        //llSay(0, msg);
        llRegionSay(0, msg);
    }else if(msg!="" && userid!=NULL_KEY){
        //llInstantMessage(userid, msg);
        llRegionSayTo(userid, 0, msg);
    }else{
        DebugMessage("Error Sending User Message: "+msg);
    }
}

// Check Security
integer SecurityCheck(key id){
    if(llListFindList(Admins, [id])==-1){
        return FALSE;
    }else{
        return TRUE;
    }
}

// Main Initialization Logic, Executed Once Upon Script Start    
Initialize(){
    Display("Update", 1, EMPTY);
    Display("Update", 2, EMPTY);
    Display("Update", 3, EMPTY);
    Display("Update", 4, EMPTY);
    Display("Update", 1, "Wholearth Elevator");
    Display("Update", 3, "Configuring...");
    SendMessage(BootMessage, llGetOwner()); // State Booting Message
    MenuComChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); // Randomize Dialog Com Channel
    SendMessage("Configuring...", llGetOwner()); // Message Owner that we are starting the Configure Loop
    cQueryID = llGetNotecardLine(ConfigFile, cLine); // Start the Read from Config Notecard
}

// System has started Function (Runs After Configuration is Loaded, as a result of EOF)
SystemStart(){
    Display("Update", 3, "System Online!");
    SendMessage("System Started!", llGetOwner());
}

// Add Admin (Add provided Legacy Name to Admins List after extrapolating userKey)
AddAdmin(string LegacyName){
    string FName = llList2String(llParseString2List(LegacyName, [" "], []), 0);
    string LName = llList2String(llParseString2List(LegacyName, [" "], []), 1);
    DebugMessage("First Name: "+FName+" Last Name: "+LName);
    key UserKey = osAvatarName2Key(FName, LName);
    if(UserKey!=NULL_KEY){
        Admins = Admins + UserKey;
        DebugMessage("Added Admin: "+LegacyName);
    }else{
        DebugMessage("Unable to Resolve: "+LegacyName);
    }
}


//  Configuration Directives Processor (Called Each Time a Line is Found in the config File)
LoadConfig(string data){
    if(data!=""){ // If Line is not Empty
        //  if the line does not begin with a comment
        if(llSubStringIndex(data, "#") != 0)
        {
        //  find first equal sign
            integer i = llSubStringIndex(data, "=");
 
        //  if line contains equal sign
            if(i != -1){
                //  get name of name/value pair
                string name = llGetSubString(data, 0, i - 1);
                //  get value of name/value pair
                string value = llGetSubString(data, i + 1, -1);
                //  trim name
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");
                //  make name lowercase
                name = llToLower(name);
                //  trim value
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");
                //  Check Key/Value Pairs and Set Switches and Lists
                if(name=="debugmode"){ // Check DeBug Mode
                    if(value=="TRUE" || value=="true"){
                        DebugMode = TRUE;
                        llOwnerSay("Debug Mode: Enabled!");
                    }else if(value=="FALSE" || value=="false"){
                        DebugMode = FALSE;
                        llOwnerSay("Debug Mode: Disabled!");
                    }
                }else if(name=="comchannel"){
                    ComChannel = (integer)value;
                    if(ComHandle!=0){
                        DebugMessage("Removing Old Com Channel...");
                        llListenRemove(ComHandle);
                    }
                    DebugMessage("Opening Com Channel ("+(string)ComChannel+")...");
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle>0){
                        DebugMessage("Com Channel Open!");
                    }else{
                        DebugMessage("Could not open Com Channel!");
                    }
                }else if(name=="elevatorkey"){
                    ElevatorKey = (key)value;
                    DebugMessage("Elevator Car: "+llKey2Name(ElevatorKey));
                }else if(name=="elevatorchannel"){
                    ElevatorChannel = (integer)value;
                    DebugMessage("Elevator Com Channel: "+(string)ElevatorChannel);
                }else if(name=="admin"){
                    AddAdmin(value);
                }else if(name=="operating"){
                    if(llToUpper(value)=="TRUE"){
                        OpMode = TRUE;
                        DebugMessage("Elevator is in Operational Mode!");
                    }else{
                        DebugMessage("Elevator is in Non-Operational Mode!");
                    }
                }else if(name=="floor"){
                    Floors = Floors + [(float)value];
                    if(llGetListLength(Floors)==1){
                        Display("Update", 3, "Reading Floor Heights");
                    }
                    DebugMessage("Floor "+(string)llGetListLength(Floors)+" Z-Axis: "+(string)llList2String(Floors, -1));
                }else if(name=="speedt"){
                    SpeedT = (float)value;
                    DebugMessage("SpeedT: "+value);
                }
        }else{ //  line does not contain equal sign
                SendMessage("Configuration could not be read on line " + (string)cLine, NULL_KEY);
            }
        }
    }
}

// Show Dialog Menu
ShowMenu(key id, string Menu){
    if(!SecurityCheck(id)){
        llRegionSayTo(id, 0, "You are not authorized to access this panel!");
        return;
    }
    llSetTimerEvent(30.0);
    OpMenu = Menu;
    if(MenuComHandle>=0){
        llListenRemove(MenuComHandle);
    }
    MenuComHandle = llListen(MenuComChannel, EMPTY, EMPTY, EMPTY);
    string CurMenuMessage = EMPTY;
    list CurMenuButtons = [];
    if(Menu=="MainMenu"){
        CurMenuMessage = MainMenuMessage;
        CurMenuButtons = MainMenuButtons;
    }
    llDialog(UserKey, CurMenuMessage, CurMenuButtons, MenuComChannel);
}

// Change LED Display
Display(string CMD, integer Line, string Text){
    if(CMD=="Update"){
        if(Text==""){
            integer i;
            for(i=1;i<5;i++){
                string Cell = "2"+(string)Line+(string)i+"000";
                llMessageLinked(LINK_SET, (integer)Cell, "",  "''''");
            }
        }else{
            integer StringLength = llStringLength(Text);
            integer SideSpaces = ((24 - StringLength) / 2 );
            integer i;
            string Message = EMPTY;
            string Spaces = EMPTY;
            for(i=1;i<=SideSpaces;i++){
                Message = Message + " ";
                if(llStringLength(Message)<22){
                    if(i==SideSpaces && llStringLength(Message)<(StringLength + SideSpaces)){
                        Message = Message + " " + Text;
                        i = 0;
                    }
                }
            }
            string Cell = "2"+(string)Line+"1000";
            integer BaseCell = (integer)Cell;
            DebugMessage("Updating Display, Line "+(string)Line+" Message: "+Message);
            llMessageLinked(LINK_SET, BaseCell, llGetSubString(Message, 1, 6), "''''");
            llMessageLinked(LINK_SET, (BaseCell + 1000), llGetSubString(Message, 7, 12), "''''");
            llMessageLinked(LINK_SET, (BaseCell + 2000), llGetSubString(Message, 13, 18), "''''");
            llMessageLinked(LINK_SET, (BaseCell + 3000), llGetSubString(Message, 19, 24), "''''");
        }
    }
}

// Execute System Command
SystemCtl(string CMD){
    
}

//Main Program Logic
/* This section contains the main program logic. (ie: Default State, and all event triggers) */

default{
    on_rez(integer params){
        llResetScript();
    }
    
    state_entry(){
        Initialize();
    }
    
    listen(integer channel, string sender, key id, string msg){
        if(channel==ComChannel){
            list InputData = llParseString2List(msg, ["||"], []);
            if(llList2String(InputData, 0)=="GETCONFIG"){
                string For = llList2String(InputData, 1);
                integer CallingFloor = llList2Integer(InputData, 2);
                list Response = [];
                string Mode;
                if(OpMode){ Mode = "TRUE"; }else{ Mode = "FALSE"; }
                if(For=="OUTCALLBUTTON"){ // Responde to Request for Config Data from OutSide Elevator Call Button
                    Response = [(string)id, "CONFIG", ElevatorKey, ComChannel, Mode];
                }else if(For=="ELEVATOR"){
                    Response = [(string)id, "CONFIG", ComChannel, Mode, SpeedT ] + Floors;
                }
                string ResponseString = llDumpList2String(Response, "||");
                llRegionSayTo(id, ComChannel, ResponseString);
                DebugMessage("Response: "+ResponseString+" was sent to: "+llKey2Name(id));
            }
        }else if(channel==MenuComChannel){ // Process Dialog Response
            if(msg=="Exit Menu"){
                
            }
            
            if(msg=="Call To"){
                ShowMenu(UserKey, msg);
            }else{
                SystemCtl(msg);
            }
        }
    }
    
    touch_start(integer num){
        UserKey = llDetectedKey(0);
        ShowMenu(UserKey, "MainMenu");
        Display("Display", 3, "Accessing Menu...");
    }
    
     // DataServer Event Called for Each Line of Config NC. This Loop It was Calls LoadConfig()
    dataserver(key query_id, string data){       // Config Notecard Read Function Needs to be Finished
        if (query_id == cQueryID){
            if (data != EOF){ 
                LoadConfig(data); // Process Current Line
                ++cLine; // Increment Line Index
                cQueryID = llGetNotecardLine(ConfigFile, cLine); // Attempt to Read Next Config Line (Re-Calls DataServer Event)
            }else{ // IF EOF (End of Config loop, and on Blank File)
                SystemStart();
            }
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            BootMessage = "Inventory Changed Detected, Re-Initializing...";
            llResetScript();
        }
    }
    
    timer(){
        llSetTimerEvent(0);
        Display("Display", 3, SystemStatusMessage);
    }
}