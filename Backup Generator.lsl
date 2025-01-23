integer __DEBUG__ = TRUE;
//integer __DEBUG__ = FALSE;

//list regions = ["Barrow", "Office"];
string configCard = "config";
list regions;

list weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
list fullWeekDays = ["Thursday","Friday","Saturday","Sunday","Monday","Tuesday","Wednesday"];
list dowInt = [4,5,6,7,1,2,3];

integer ncline;
key rqid;

string basePath;
string daily_path;
string weekly_path;
string monthly_path;
integer BackupHour = 14;

integer SECS_DAY = 86400;
integer SECS_WEEK = 604800;

debug( string text ){
    if( __DEBUG__ ){
        llOwnerSay( text );
    }
}

forceDebug( string data ){
    integer dddbg = __DEBUG__;
    __DEBUG__ = TRUE;
    debug(data);
    __DEBUG__ = dddbg;
}

loadConfig(){
    llSetTimerEvent(0.0);
    llOwnerSay("Loading config");
    ncline = -1;
    getNextNCLine("");
}

getNextNCLine( string data ){
    if( data != "" ){
        parseData( data );
    }
    ncline++;
    rqid = llGetNotecardLine( configCard, ncline);
}

parseData( string data ){
    if( llGetSubString( data, 0, 0 ) == "[" ){
        forceDebug(llGetSubString(data,1,-2));
    }
    else if( llGetSubString( data, 0, 0 ) != "#" ){
        list en = llParseString2List( data, ["="], [] );
        string token = llList2String(en,0);
        string value = llList2String(en,1);
        if( token == "Path" ){
            basePath = value;
            //value = osReplaceString( value, "%r", regionName, -1, 0 );
        }
        else if( token == "Region" ){
            regions = regions + [value];
        }
        else if( token == "BackupHour" ){
            BackupHour = (integer) value;
        }
    }
}

integer isOn( string value ){
    return llToUpper(value) == "ON";
}

string getMonth(){
    return pad( llGetSubString( llGetTimestamp(), 5, 6 ), "00" );
}

// contributed by wrGodLikeBeing
string timestamp2weekday( integer ts ){
    return llList2String( fullWeekDays,(ts/86400)%7 );
}

// returns day of week as an integer, with Sunday as start of week (0), or Monday
string timestamp2WeekdayInteger( integer ts ){
    return llList2String( dowInt, (ts/86400)%7 );
    integer offset = 3;
    if( MondayStart ) offset++;
    ts = ts - (86400*2);
    
    integer dow = (((ts/86400)%7)+offset)%7;
    return dow;
}

string pad( string what, string with ){
    what = with+what;
    return llGetSubString( what, -llStringLength(with), -1 );
    
}

backupList(){
    integer l = llGetListLength( regions );
    integer i = 0;
    while( i < l ){
        backupRegion( llList2String( regions, i ) );
        i++;
    }
    setDailyTimer();
}

integer consoleCommand( string command ){
    return osConsoleCommand( command );
}

integer backupRegion( string region ){
    integer time = llGetUnixTime();
    string day = timestamp2weekday(time);
    string dow = pad( (string) timestamp2WeekdayInteger( time ), "00" );
    string path;
    string oar;
    string command;
    // first of all, do a normal weekday backup
    path = osReplaceString( basePath, "%r", region, -1, 0 );
    oar = "D-"+dow+"-"+day;
    command = "save oar "+path+oar+".oar";

    integer result = osConsoleCommand("change region "+region);
    if( result ){
        llOwnerSay("Backing up region '"+region+"'");
        //llOwnerSay( "Daily Backup region '"+region+"'" );
        result = consoleCommand( command );
        //llOwnerSay(  "Backup command completed="+result );
        
        // is this a monday? (we start the week on a monday, 'cos it makes business sense
        if( dow == "01" ){
            integer week = (time - (time % SECS_DAY)) / SECS_WEEK;
            oar = "W-"+pad( (string)week, "00" )+"-"+getMonth();
            command = "save oar "+path+oar+".oar";
            //llOwnerSay( "Weekly Backup region '"+region+"'" );
            result = consoleCommand( command );
            //llOwnerSay(  "Backup command completed="+result );
        }
        if( llGetSubString( llGetTimestamp(), 5, 9 ) == "12-31" ){
            oar = "Y-"+llGetSubString( llGetTimestamp(), 0, 18 );
            oar = osReplaceString( oar, "T", "-", -1, 0 );
            command = "save oar "+path+oar+".oar";
            //llOwnerSay( "Annual Backup region '"+region+"'" );
            result = consoleCommand( command );
            //llOwnerSay(  "Backup command completed="+result );
        }
    }
    return result;
}

setDailyTimer(){
    // calculate 2PM tomorrow
    integer tomorrow = llGetUnixTime() % 86400; // current time today
    integer today = llGetUnixTime() - tomorrow; // start of today
    tomorrow = today + 86400 + (BackupHour*3600); // tomorrow 2pm
    float difference = (float) (tomorrow - llGetUnixTime()); // diff between now and 2pm tomorrow
    llSetTimerEvent( difference );
    llOwnerSay( "Timer set to go off in "+diff2Time( (integer) difference ) );
}

string diff2Time( integer diff ){
    integer h = diff / 3600;
    diff = diff % 3600;
    integer m = diff / 60;
    diff = diff % 60;
    return pad( (string) h, "00" )+":"+pad( (string) m, "00" )+":"+pad( (string) diff, "00" );
}
    
default {
    state_entry() {
        llSetText("",<0,0,1>,1.0);
        getNextNCLine("");
    }
    changed( integer change ){
        if( change & CHANGED_OWNER ){
            llSetScriptState(llGetScriptName(),FALSE);
            llSleep(0.1);
        }
    }
    dataserver( key id, string data ){
        if( id == rqid ){
            if( data == EOF ){
                backupList();
            }
            else {
                getNextNCLine( data );
            }
        }
    }
    timer(){
        backupList();
    }
}
