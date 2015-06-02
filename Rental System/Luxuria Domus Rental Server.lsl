// Game Server Relay Engine v1.0
// Created by Tech Guy


// Configuration

    // Constants
integer ServerComChannel = -63473670; // Secret Negative Channel for Server Communication
list KEYS = [ "5b8c8de4-e142-4905-a28f-d4d00607d3e9", "b9dbc6a4-2ac3-4313-9a7f-7bd1e11edf78", "dbfa0843-7f7f-4ced-83f6-33223ae57639" ];
list AuthedUsers = [];
string EMPTY = "";
key SecurityKey = "3d7b1a28-f547-4d10-8924-7a2b771739f4";
float LightHoldLength = 0.1;
string SecureRequest = "TheKeyIs(Mq=h/c2)";
string cName = ".config"; // Name of Configuration NoteCard
    // Off-World Data Communication Constants
key HTTPRequestHandle; // Handle for HTTP Request
string URLBase = "http://api.orbitsystems.ca/api.php";
list HTTPRequestParams = [
    HTTP_METHOD, "POST",
    HTTP_MIMETYPE, "application/x-www-form-urlencoded",
    HTTP_BODY_MAXLENGTH, 16384,
    HTTP_CUSTOM_HEADER, "CUSKEY", "TheKeyIs(Mq=h/c2)"
];


        // Indicator Light Config
    float GlowOn = 0.10;
    float GlowOff = 0.0;
    list ONColorVectors = [<0.0,1.0,0.0>,<1.0,0.5,0.0>,<1.0,0.0,0.0>];
    list ColorNames = ["Green", "Orange", "Red"];
    list OFFColorVectors = [<0.0,0.5,0.0>,<0.5,0.25,0.0>,<0.5,0.0,0.0>];
    integer PWRLIGHT = 2;
    integer CFGLIGHT = 3;
    integer INLIGHT = 4;
    integer OUTLIGHT = 5;
    
    

    // Variables
integer ServerComHandle; // Hold Handle to Control Server Com Channel
integer cLine; // Holds Configuration Line Index for Loading Config Loop
key cQueryID; // Holds Current Configuration File Line during Loading Loop
string GameName = "";
    // Switches
integer DebugMode = FALSE; // Are we running in with Debug Messages ON?
    // Flags

// User Database Configuration Directives
string UserUploadTimer;
    
    // Functions

Initialize(){
    llListenRemove(ServerComHandle);
    llSleep(LightHoldLength);
    llListen(ServerComChannel, EMPTY, EMPTY, EMPTY);
    if(DebugMode){
        llOwnerSay(llGetObjectName()+" Server Online");
    }
    llOwnerSay("Configuring...");
    cQueryID = llGetNotecardLine(cName, cLine);
}

LightToggle(integer LinkID, integer ISON, string Color){
    if(ISON){
        vector ColorVector = llList2Vector(ONColorVectors, llListFindList(ColorNames, [Color]));
        llSetLinkPrimitiveParamsFast(LinkID, [
            PRIM_COLOR, ALL_SIDES, ColorVector, 1.0,
            PRIM_GLOW, ALL_SIDES, GlowOn,
            PRIM_FULLBRIGHT, ALL_SIDES, TRUE
        ]);
    }else{
        vector ColorVector = llList2Vector(OFFColorVectors, llListFindList(ColorNames, [Color]));
        llSetLinkPrimitiveParamsFast(LinkID, [
            PRIM_COLOR, ALL_SIDES, ColorVector, 1.0,
            PRIM_GLOW, ALL_SIDES, GlowOff,
            PRIM_FULLBRIGHT, ALL_SIDES, FALSE
        ]);
    }
}

LoadConfig(string data){
    LightToggle(CFGLIGHT, TRUE, "Orange");
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
                if(name=="debugmode"){
                    if(value=="TRUE" || value=="true"){
                        DebugMode = TRUE;
                        llOwnerSay("Debug Mode: Enabled!");
                    }else if(value=="FALSE" || value=="false"){
                        DebugMode = FALSE;
                        llOwnerSay("Debug Mode: Disabled!");
                    }
                }
                LightToggle(CFGLIGHT, FALSE, "Orange");
        }else{ //  line does not contain equal sign
                llOwnerSay("Configuration could not be read on line " + (string)cLine);
            }
        }
    }
}

RegisterServer(string cmd){
    if(cmd=="CheckReg"){
        string CmdString = "?"+llStringToBase64("cmd")+"="+llStringToBase64("CheckReg")+"&"+llStringToBase64("Key")+"="+llStringToBase64(SecurityKey);
        string URL = URLBase + CmdString;
        list SendParams = HTTPRequestParams + ["ServerType", "Main"];
        HTTPRequestHandle = llHTTPRequest(URL, SendParams, ""); // Send Request to Server to Check and/or Register this Server
    }
}

    
// Main Program
default{
    on_rez(integer params){
        //llGiveInventory(llGetOwner(), llGetInventoryName(INVENTORY_NOTECARD, 1));
        llResetScript();
    }
    
    state_entry(){
        LightToggle(PWRLIGHT, TRUE, "Red");
        llSleep(LightHoldLength);
        LightToggle(CFGLIGHT, TRUE, "Orange");
        llSleep(LightHoldLength);
        LightToggle(CFGLIGHT, FALSE, "Orange");
        LightToggle(INLIGHT, TRUE, "Green");
        llSleep(LightHoldLength);
        LightToggle(INLIGHT, FALSE, "Green");
        LightToggle(OUTLIGHT, TRUE, "Green");
        llSleep(LightHoldLength);
        LightToggle(OUTLIGHT, FALSE, "Green");
        Initialize();
    }
    
    dataserver(key query_id, string data){       // Config Notecard Read Function Needs to be Finished
        if (query_id == cQueryID){
            if (data != EOF){ 
                LoadConfig(data); // Process Current Line
                ++cLine; // Incrment Line Index
                cQueryID = llGetNotecardLine(cName, cLine); // Attempt to Read Next Config Line (Re-Calls DataServer Event)
            }else{ // IF EOF (End of Config loop, and on Blank File)
                LightToggle(CFGLIGHT, TRUE, "Orange");
                // Check if Server is Registered with Website
                RegisterServer("CheckReg");
            }
        }
    }
    
    changed(integer c){
        if(c & CHANGED_INVENTORY){
            llResetScript();
        }
    }
    
    listen(integer chan, string cmd, key id, string data){
        if(DebugMode){
            llOwnerSay("GS Listen Event Fired!\r"+data);
        }
        LightToggle(INLIGHT, TRUE, "Green");
//        llSleep(LightHoldLength);
        
    }
    
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (request_id != HTTPRequestHandle) return;// exit if unknown
 
        vector COLOR_BLUE = <0.0, 0.0, 1.0>;
        float  OPAQUE     = 1.0;
 
        list OutputData = llCSV2List(body); // Parse Response into List
        string InputKey = llBase64ToString(llList2String(OutputData, 1));
        string InputCMD = llBase64ToString(llList2String(OutputData, 0));
        if(InputKey!=SecurityKey){
            llOwnerSay("Invalid Security Key Received from RL Server!\r"+body);
        }else{
            if(InputCMD=="ALRDYREGOK"){ // Server Already Registered
                if(DebugMode){
                    llOwnerSay("Server Already Registered!");
                }
            }else if(InputCMD=="REGOK"){ // Server Successfully Registered
                if(DebugMode){
                    llOwnerSay("Server Successfully Registered!");
                }
            }else if(InputCMD=="REGERR"){ // Error Registering Server with Off-World Database
                llOwnerSay("Error Registering Server with Database!");
            }else if(InputCMD=="CHECKERR"){ // Error Checking Database for Server Registration
                llOwnerSay("Error Checking Database for Server Registration");
            }else{
                llOwnerSay("Response from server not reconignized!");
            }
        }
        llOwnerSay(llGetObjectName()+" Server Online");
        LightToggle(CFGLIGHT, FALSE, "Orange");
    }
}