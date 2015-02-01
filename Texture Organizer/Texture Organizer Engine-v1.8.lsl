//Configuration Variables
string ReasonBroken = ""; // Hold Reason we entered a broken state
string HelpCard = "Organizer Help Card";

vector SculptieOffset = <1.0,0.0,0.0>;
integer SculptieHidden = TRUE;

string AuthCard = ".whitelist"; // Contains Name of NC containing authorized people to use organizer
list AuthedUsers = []; // List Containing Authorized Users as read from Config File.
key notecardQueryId;
 // script-wise, the first notecard line is line 0, the second line is line 1, etc.
integer notecardLine;

// Handles
integer DHandleChannel = 18006;
integer DHandle;


// Prim and Face IDs
integer MainDisplay = 2;
integer DisplayFace = 4;
list DisplayGrid = [52,50,48,46,44,42,40,38,36,34,32,30,28,26,24,22,20,18,16,14,12,10,8,6,4];
list SculptGrid =  [51,49,47,45,43,41,39,37,35,33,31,29,27,25,23,21,19,17,15,13,11,9,7,5,3];

// Texture Lists
list maintextureids = [];
list maintexturenames = [];
list textureids = [];
list texturenames = [];
integer NumTextures; // Hold Total Number of Textures (So we do not have to constantly recalculate)
integer TIndex; // Hold Index Number of Current Texture in Main Viewer
integer StartIndex; // Holds Index Number for Texture in Prim 3
integer EndIndex;  // Holds Index Number for Texture in Prim 27

// Pure Variable
list temp; // Any Temp List
string Name; // Any Random Name (Usually Texture Name during Delete
string DialogBox = ""; // Hold flag naming last used dialog
string GetCatFlag = ""; // Hold Flag to tell listener what is expected next
string CurrentCategory = "Main";
integer FromUpdate = FALSE;
integer Sculpties = FALSE;
// User Configurable Switches

//Custom Functions

LoadInventory(){
    integer InvNum = llGetInventoryNumber(INVENTORY_TEXTURE);
    if(InvNum<=0){ // If we have no textures
        ReasonBroken = "InvEmpty";
        state broken;
    }else{ // We Found Textures so Process Them
        integer i; // Hold Iterative Index Counter
        for(i=0;i<=InvNum-1;i++){
            string TextureName = llGetInventoryName(INVENTORY_TEXTURE, i);
            //integer isok = CheckPerms(TextureName);
            
            //if(isok==TRUE){
                texturenames = texturenames + TextureName;
                key TextureKey = llGetInventoryKey(llList2String(texturenames,i));
                if(TextureKey!=NULL_KEY){
                    textureids = textureids + TextureKey;
                    //llOwnerSay("Texture: "+llList2String(texturenames, i)+"\nID: "+llList2String(textureids, i)+"\nHas been sucessfully added");
                }else{
                    //llOwnerSay("TextureName: "+llList2String(texturenames, i));
                }
            //}else{
                
            //}
        }
        NumTextures = llGetListLength(textureids); // Make note of how many texture we have in inventory lists
        maintextureids = textureids;
        maintexturenames = texturenames;
        llOwnerSay("Inventory Loaded!");
    }
}

integer CheckPerms(string TName){
    integer permCode = llGetInventoryPermMask(TName, MASK_NEXT);
    if(~permCode & PERM_ALL){
        llOwnerSay("Item: "+TName+" is not marked as FULL PERMISSIONS. Please Correct This,\n Texture will not be included in library for this load...");
        return TRUE;
    }else{
        return TRUE;
    }
}

Init(){ // Start Displaying Textures and switch to running state
    llOwnerSay("Displaying Textures...");
    integer i; // Iterative ID Index
    integer InvNum = llGetListLength(textureids);
    if(InvNum<25){ // Then we use the index of the Inventory to assign textures
        for(i=0;i<=InvNum-1;i++){
             llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, i), [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
        }
        StartIndex = 0;
        EndIndex = InvNum-1; // Because the inventory of textures will not fill up the first grid the end id will be the intentory total minus 1
    }else{ // Then we simply count from 0 - 24
        for(i=0;i<=24;i++){
             llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, i), [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
        }
        StartIndex = 0;
        EndIndex = 24;
    }
    if(!Sculpties){
        for(i=0;i<=24;i++){
            llMessageLinked(llList2Integer(SculptGrid, i), 0, "hide", NULL_KEY); 
        }
    }
        // Set Main Viewer to 1st Texture
    TIndex = 0; // Set Main Texture Index to 0 as we are loading from the start.
    llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(textureids, 0), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
    llOwnerSay("Textures Displayed");
    state running;
}

UpdateGrid(string Direction){
    integer i; // Iterative Index
    integer gridid; // Track Grid Array
    if(Direction=="FWD"){
        for(i=StartIndex;i<=StartIndex+25;i++){
            if(Sculpties){
                if(llList2String(textureids, i)==""){
                    llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "hide", NULL_KEY);
                }else{
                    llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "show", NULL_KEY);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(SculptGrid, gridid), [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2String(textureids, i), PRIM_SCULPT_TYPE_PLANE]);
                if(i==StartIndex){
                    llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                gridid++;
            }else if(!Sculpties){
                llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "hide", NULL_KEY);
                if(i==StartIndex){
                    llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                gridid++;
            }
        }
    }else if(Direction=="REV"){
        for(i=StartIndex;i<=StartIndex+25;i++){
            if(Sculpties){
                if(llList2String(textureids, i)==""){
                    llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "hide", NULL_KEY);
                }else{
                    llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "show", NULL_KEY);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(SculptGrid, gridid), [PRIM_TYPE, PRIM_TYPE_SCULPT, llList2String(textureids, i), PRIM_SCULPT_TYPE_PLANE]);
                if(i==StartIndex){
                    llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                gridid++;
            }else if(!Sculpties){
                llMessageLinked(llList2Integer(SculptGrid, gridid), 0, "hide", NULL_KEY);
                if(i==StartIndex){
                    llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                }
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, gridid), [PRIM_TEXTURE, DisplayFace, llList2String(textureids, i), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
                gridid++;
            }
        }
    }
    if(!Sculpties){
        llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(textureids, StartIndex), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
    }else{
        llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
    }
}

ProcessWhiteList(string inputSTR){
    if(inputSTR=="get"){
        if (llGetInventoryKey(AuthCard) == NULL_KEY)
            {
                llOwnerSay( "Notecard '" + AuthCard + "' missing or unwritten");
                // Possible Broken State
            }
        llOwnerSay("Reading Authorized Users from '" + AuthCard + "'.");
        notecardQueryId = llGetNotecardLine(AuthCard, notecardLine);
    }else{
        integer spaceIndex = llSubStringIndex(inputSTR, " ");
        string  firstName  = llGetSubString(inputSTR, 0, spaceIndex - 1);
        string  lastName  = llGetSubString(inputSTR, spaceIndex + 1, -1);
        string  AuthedID = osAvatarName2Key(firstName, lastName);
        if(AuthedID!=""){
            AuthedUsers = AuthedUsers + [AuthedID];
        }else{
            llOwnerSay("Invalid Username in WhiteList NoteCard.");
        }
    }
}

// Main States
default
{
    on_rez(integer start_params){
        llOwnerSay("Resetting...");
        llResetScript();
    }
    
    state_entry()
    {
        llListenRemove(DHandle);
        llOwnerSay("Loading...");
        textureids = [];
        texturenames = [];
        maintextureids = [];
        maintexturenames = [];
        Sculpties = FALSE;
        LoadInventory();
        ProcessWhiteList("get");
    }
    
    dataserver(key query_id, string data){
        if (query_id == notecardQueryId){
            if (data == EOF){
                llOwnerSay("Done reading whitelist notecard, added " + (string) notecardLine + " authorized users.");
                Init();
            }else{
                // bump line number for reporting purposes and in preparation for reading next line
                ProcessWhiteList(data);
                ++notecardLine;
                llOwnerSay("Authorized User: " + (string) notecardLine + " " + data);
                notecardQueryId = llGetNotecardLine(AuthCard, notecardLine);
            }
        }
    }
    
}
    // Broken State
state broken{ 
    state_entry(){
        if(ReasonBroken=="InvEmpty"){
            llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
            integer i;
            for(i=0;i<25;i++){
                llSetLinkPrimitiveParamsFast(llList2Integer(DisplayGrid, i), [PRIM_TEXTURE, DisplayFace, "940333d1-4838-46f2-9331-58de6e726fa6", <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
            }
            llOwnerSay("You have no textures in the organizers inventory. Please add some...");
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            llSetTimerEvent(7.5);
        }
    }
    
    timer(){
        llOwnerSay("Inventory Change Detected, Resetting...");
        llResetScript();
    }
    
    link_message(integer sender, integer num, string message, key userid){
        if(message=="help"){
            llSay(0, "Please Take Help Card...");
            llGiveInventory(userid, HelpCard);
        }
    }
}

state running{
    state_entry(){
        llOwnerSay("Running");
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            llSetTimerEvent(7.5);
        }
    }
    
    link_message(integer sender, integer num, string message, key userid){
        if(message=="gridpush"){ // Someone pushed on a small texture
            list temp = llGetLinkPrimitiveParams(num, [PRIM_TEXTURE, DisplayFace]);
            llOwnerSay(llList2String(temp, 0));
            llSetLinkPrimitiveParamsFast(MainDisplay, [PRIM_TEXTURE, DisplayFace, llList2String(temp, 0), <1.0, 1.0, 0.0>, ZERO_VECTOR,0.0]);
        }else if(message=="MAIN"){
            textureids = [] + maintextureids;
            texturenames = [] + maintexturenames;
            NumTextures = llGetListLength(textureids);
            StartIndex = 0;
            TIndex = 0;
            Sculpties = FALSE;
            UpdateGrid("FWD");
        }else if(message=="mainpush"){ // Someone pushed on the Main Texture
            if(userid==llGetOwner() || llListFindList(AuthedUsers, [userid])!=-1){
                llOwnerSay("Giving Texture...");
                temp = llGetLinkPrimitiveParams(MainDisplay, [PRIM_TEXTURE, DisplayFace]);
                Name = llList2String(texturenames, llListFindList(textureids, llList2String(temp, 0)));
                if(llGetInventoryType(Name)==INVENTORY_NONE){
                    llMessageLinked(LINK_ALL_CHILDREN, 0, Name, userid);
                }else{
                    llGiveInventory(userid, Name);
                }
            }else{
                llSay(0, "Yes that is a nice texture isn't it!\nIf you would like one of your own texture organizers contact Tech Guy.");
            }
        }else if(message=="next"){ // Go to Previous Texture Grid
           if(NumTextures<=25){ // If all we have is 25 or less textures there is no need to try and adjust the grid
               llSay(0, "These are the only textures in inventory!");
            }else if((StartIndex+25)>NumTextures){
                llSay(0, "You are at the end!");
            }else{
                StartIndex = StartIndex + 25;
            }
            UpdateGrid("FWD");
        }else if(message=="prev"){ // Go to Next Grid
            if(NumTextures<=25){ // If all we have is 25 or less textures there is no need to try and adjust the grid
               llSay(0, "These are the only textures in inventory!");
            }else if(StartIndex==0){
               llSay(0, "You are already at the start!");
            }else{
                StartIndex = StartIndex - 25;
            }
            UpdateGrid("REV");
        }else if(message=="delete"){ // Remove Texture that is in Main Viewer from Inventory and Lists
            if(userid==llGetOwner()){ // If Owner of Object has request Delete!
                llListenRemove(DHandle);
                DHandle = llListen(DHandleChannel, "", userid, "");
                temp = llGetLinkPrimitiveParams(MainDisplay, [PRIM_TEXTURE, DisplayFace]);
                Name = llList2String(texturenames, llListFindList(textureids, llList2String(temp, 0)));
                DialogBox = "DELETE";
                llDialog(userid, "Are you sure you would like to remove texture named:\n"+Name+"?", ["Yes", "No", "Cancel"], DHandleChannel);
            }else{ // Someone other than other clicked Delete
                llSay(0, "You do not own me, therefore you can not delete me!\n If you want a copy of this organizer contact Tech Guy");
            }
        }else if(message=="config"){ // Pop-Up Configure Dialog Box
            
        }else if(message=="help"){ // Give Help Card
            llGiveInventory(userid, HelpCard);
        }else if(message=="catchange"){
            GetCatFlag = "getids"; // Set Flag to Waiting for ID List
            Sculpties = FALSE;
            llMessageLinked(sender, 0, "getids", "");
        }else if(message=="SCULPTIES"){
            GetCatFlag = "getids"; // Set Flag to Waiting for ID List
            Sculpties = TRUE;
            llMessageLinked(sender, 0, "getids", "");
        }else if(GetCatFlag=="getids"){ // If we get a response and that flag equals that :-p
            textureids = [];
            textureids = llCSV2List(message);
            if(llList2String(textureids, 0)==""){
                llOwnerSay("ERROR");
            }else{
                StartIndex = 0;
                NumTextures = llGetListLength(textureids);
                GetCatFlag = "getnames";
                llMessageLinked(sender, 0, "getnames", "");
            }
        }else if(GetCatFlag=="getnames"){
            texturenames = [];
            texturenames = llCSV2List(message);
            if(llList2String(texturenames, 0)==""){
                llOwnerSay("ERROR Receiving names...");
            }else{
                GetCatFlag = "";
                UpdateGrid("FWD");
            }
        }else if(message=="UPDATED"){
           GetCatFlag = "getids"; // Set Flag to Waiting for ID List
           llMessageLinked(sender, 0, "getids", "");
        }
    }
    
    listen(integer channel, string name, key id, string message){
        if(channel==DEBUG_CHANNEL){
            llOwnerSay(message);
        }
        if(channel==DHandleChannel){
            if(DialogBox=="DELETE"){
                if(id==llGetOwner()){
                    if(llGetInventoryType(Name)!=INVENTORY_NONE){
                        llRemoveInventory(Name);
                        llOwnerSay("Texture Removed");
                        state default;
                    }else{                    
                        llMessageLinked(LINK_ALL_CHILDREN, 2, Name, id);
                    }
                }
            }
        }
    }
    
    timer(){
        llOwnerSay("Inventory Change Detected, Resetting...");
        llResetScript();
    }
}