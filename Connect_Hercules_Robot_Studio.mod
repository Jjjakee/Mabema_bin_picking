MODULE Module1
    CONST robtarget Target_50:=[[1077.008,-825,1150],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_10:=[[524.584,1228.139,1077.999],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_20:=[[921.161,1228.14,1078],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_30:=[[889,1368,1060],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_40:=[[557,1368,1060],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_60:=[[1437.886510893,357.30604988,1030.161500163],[0.893132719,0.000000006,-0.000000005,-0.449793226],[0,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_70:=[[1013.324692703,-909.319395992,1196.702690641],[0.672147852,0.011443731,-0.044409036,-0.738995361],[-1,-1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    VAR robtarget Target_hercules:=[[889,1368,1060],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    !***********************************************************
    ! SafeMove variables
    ! Interuptnumbers for violated fields
    VAR intnum WarningField_v;
    VAR intnum ProtectiveField_v;
    VAR intnum allfree;
   
    !
    !***********************************************************
    VAR string stReceived;
    VAR socketdev ComSocket;
    
    PROC main()
        ! Creates a socket variable
        SocketCreate ComSocket;
        ! Ip address of current PC, port number defined in Hercules. Can use the IP address of other pc also.
        ! Connects to Hercules server
        SocketConnect ComSocket,"127.0.0.1",5001;

        GetData;
        SocketClose ComSocket;
    ENDPROC
    
    
    
    PROC Path_10()
        MoveJ Target_60,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveJ Target_70,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveL Offs(Target_70,0,0,-50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        WaitTime 1.0;
        MoveL Offs(Target_70,0,0,50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        MoveJ Target_10,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveL Offs(Target_10,0,0,-50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        WaitTime 1.0;
        MoveL Offs(Target_10,0,0,50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        MoveJ Target_20,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveL Offs(Target_20,0,0,-50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        WaitTime 1.0;
        MoveL Offs(Target_20,0,0,50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        MoveJ Target_30,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveL Offs(Target_30,0,0,-50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        WaitTime 1.0;
        MoveL Offs(Target_30,0,0,50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        MoveJ Target_40,v1000,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveL Offs(Target_40,0,0,-50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
        WaitTime 1.0;
        MoveL Offs(Target_40,0,0,50), v100, fine, tGroup1gripperTool\WObj:=wobj0;
    ENDPROC
    
    PROC GetData()
        VAR string X:="";
        VAR string Y:="";
        VAR string Z:="";
        VAR string XData:="";
        VAR string YData:="";
        VAR string AngleData:="";
        VAR string sData:="";
        VAR string sTemp;
        VAR num NumCharacters:=6;
        VAR num delim_pos;
        VAR bool bOK;
        VAR socketstatus status;
    
        status:=SocketGetStatus(ComSocket);
        IF status<>SOCKET_CONNECTED THEN
            TPErase;
            TPWrite "Vision Sensor Not Connected";
            Return;
        ENDIF
    
        !Instruct In-Sight to Acquire an Imane and not return until complet
        SocketSend ComSocket\Str:="sw8"+"\0D\0A";
        !CheckStatus;
    
        SocketSend ComSocket\Str:="GVJob.Robot.FormatString"+"\0D\0A";
    
        ! Read the data 
        ! gets the status and data in one packet "1\0D\0A\123.4567.89012.345\0D\0A"
        SocketReceive ComSocket\Str:=stReceived;    
        sData:=stReceived;
        TPWrite "After GV: "+stReceived;
        
        Target_hercules := StringToTarget(stReceived);
        
        
    ENDPROC
    
    FUNC robtarget StringToTarget(string value)
        VAR robtarget tmpTarget;
        VAR bool bResult;
        
        VAR num posX;
        VAR num posY;
        VAR num posZ;
        
        ! Finds the position of first ";" in the string
        posX := StrFind(value,1,";");
        posY := StrFind(value,posX+1,";");
        posZ := StrFind(value,posY+1,";");
        
        bResult:=StrToVal(StrPart(value,1,posX-1),tmpTarget.trans.x);
        bResult:=StrToVal(StrPart(value,posX+1,posY-posX-1),tmpTarget.trans.y);
        bResult:=StrToVal(StrPart(value,posY+1,posZ-posY-1),tmpTarget.trans.z);
        
        RETURN tmpTarget;
    ENDFUNC
    
    PROC CheckStatus()
        VAR string sData:="";
        SocketReceive ComSocket\Str:=stReceived;
        sData:=stReceived;
        ! if not 1
        IF strPart(stReceived,1,1)<>"1" THEN 
            TPErase;
            TPWrite "Vision Error!";
            Stop;
        ENDIF
    ENDPROC
    
    
    PROC main_()
        Path_10;
    ENDPROC

ENDMODULE